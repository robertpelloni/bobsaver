#version 420

// original https://www.shadertoy.com/view/lsdcW7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*!
 * <info>
 *
 * Menger Sponge Tour - flight along the Catmull-Rom spline
 * 
 * This really nice layered variation of a Menger Sponge
 * was designed by Shane: https://www.shadertoy.com/view/ldyGWm
 * 
 * Also the lighting is from him. It's unusual, but... that's why I like it :)
 * So I only tweaked it a bit and parameterized it, as I'm usually working 
 * in Synthclipse. The most tweaks went to shadowing, as it was giving some bad 
 * artifatcs, like circles.
 *
 * The flight is done using an 8-points path. This path is looped, and calculated
 * using Catmull-Rom spline.
 * There's a problem with some segments combinations, though. It can result in a jump -
 * and maybe even in a completely black frame :/ if you can see, what's wrong, please note me.
 * 
 * If you want, you can watch the high quality render with some music here:
 * https://youtu.be/Wcl7td4yXfA
 *
 * </info>
 */

// Flight speed. Total duration will be 8*flightSpeed.
const float flightSpeed = 0.125; //! slider[0.1, 0.25, 2]
// Field of view
const float FOV = 2.; //! slider[0.5, 2, 4]
// Gamma correction
const float Gamma = .75; //! slider[0.1, 0.8, 3.0]
// Darker parts of panels texturing
const vec3 darkColor = vec3(.329,.078,.5); //! color[.4, .2, .1]
// Fog distance
const float fogDistance = 24.; //! slider[10, 24, 100]
// Fog color
const vec3 fogColor = vec3(1.,0.,.12); //! color[1, 0, 0.12]
// Light position
const float lightDistance = -.15; //! slider[-2, -.15, 2]
// AO iterations
const int aoIterations = 5; //! slider[1, 5, 10]
// Shadow light
const float shadowLight = .45; //! slider[0, 0.5, 1]

float hash( float n ){ return fract(cos(n)*45758.5453); }

// Smooth minimum function. There are countless articles, but IQ explains it best here:
// http://iquilezles.org/www/articles/smin/smin.htm
float sminP( float a, float b, float smoothing ){

    float h = clamp( 0.5+0.5*(b-a)/smoothing, 0.0, 1.0 );
    return mix( b, a, h ) - smoothing*h*(1.0-h);
}

// This layered Menger sponge is stolen from Shane
// https://www.shadertoy.com/view/ldyGWm
// Just modified it a bit, but its main construction is his idea - and I love it :)
float map(vec3 q)
{
     vec3 p = abs(fract(q/3.)*3. - 1.5);
     float d = min(max(p.x, p.y), min(max(p.y, p.z), max(p.x, p.z))) - 1. + .04;

    p =  abs(fract(q) - .5);
     d = max(d, min(max(p.x, p.y), min(max(p.y, p.z), max(p.x, p.z))) - 1./3. + .05);

    p =  abs(fract(q*2.)*.5 - .25);
     d = max(d, min(max(p.x, p.y), min(max(p.y, p.z), max(p.x, p.z))) - .5/3. - .015);

    p =  abs(fract(q*3./.5)*.5/3. - .5/6.);

    return max(d, min(max(p.x, p.y), min(max(p.y, p.z), max(p.x, p.z))) - 1./27. - .015);
}

// Raymarching
float trace(vec3 ro, vec3 rd){

    float t = 0., d;
    for(int i=0; i< 48; i++){
        d = map(ro + rd*t);
        if (d <.0025*t || t>fogDistance) break;
        t += d;
    }
    return t;
}

// Reflections
float refTrace(vec3 ro, vec3 rd)
{
    float t = 0., d;
    for(int i=0; i< 16; i++){
        d = map(ro + rd*t);
        if (d <.0025*t || t>fogDistance) break;
        t += d;
    }
    return t;
}

// Tetrahedral normal (from IQ)
vec3 normal(in vec3 p)
{
    // Note the slightly increased sampling distance, to alleviate artifacts due to hit point inaccuracies.
    vec2 e = vec2(0.003, -0.003);
    return normalize(e.xyy * map(p + e.xyy) + e.yyx * map(p + e.yyx) + e.yxy * map(p + e.yxy) + e.xxx * map(p + e.xxx));
}

// Ambient occlusion, for that self shadowed look.
// XT95 came up with this particular version. Very nice.
//
// Hemispherical SDF AO - https://www.shadertoy.com/view/4sdGWN
// Alien Cocoons - https://www.shadertoy.com/view/MsdGz2
float calculateAO(in vec3 p, in vec3 n)
{
    float ao = 0.0, l;
    const float falloff = 1.;

    const float maxDist = 1.;
    for(float i=1.; i<float(aoIterations)+.5; i++){

        l = (i + hash(i))*.5/float(aoIterations)*maxDist;
        ao += (l - map( p + n*l ))/ pow(1. + l, falloff);
    }

    return clamp( 1.-ao/float(aoIterations), 0., 1.);
}

// Soft shadows.
// Its params are very sensitive and can cause
// some really bad artifacts.
float softShadow(vec3 ro, vec3 lp, float k)
{
    const int maxIterationsShad = 32;

    vec3 rd = (lp-ro); // Unnormalized direction ray.

    float shade = 1.0;
    float dist = 0.002;
    float end = max(length(rd), 0.001);
    float stepDist = end/float(maxIterationsShad);

    rd /= end;

    for (int i=0; i < maxIterationsShad; i++){

        float h = map(ro + rd*dist);
        shade = min(shade, smoothstep(0.0, 1.0, k*h/dist)); // Subtle difference. Thanks to IQ for this tidbit.
        dist += clamp(h, 0.0001, 0.2);

        // Early exit
        if (h < 0.00001 || dist > end) break;
    }

    // Light the shadows up
    return min(max(shade, 0.) + shadowLight, 1.0);
}

vec3 camPathTable[8];
void setCamPath()
{
    const float mainCorridor = 2.82*2.;

    // right now it's only through the main corridors.
    // it'd be nice to enter also the smaller ones, too :)
    camPathTable[0] = vec3(0, 0, 0);
    camPathTable[1] = vec3(0, 0, mainCorridor);
    camPathTable[2] = vec3(0, -mainCorridor, mainCorridor);
    camPathTable[3] = vec3(mainCorridor, -mainCorridor, mainCorridor);
    camPathTable[4] = vec3(mainCorridor, -mainCorridor, 0);
    camPathTable[5] = vec3(0, -mainCorridor, 0);
    camPathTable[6] = vec3(-mainCorridor, -mainCorridor, 0);
    camPathTable[7] = vec3(-mainCorridor, 0, 0);
}

/*
 * http://graphics.cs.ucdavis.edu/education/CAGDNotes/Catmull-Rom-Spline/Catmull-Rom-Spline.html
 * f(x) = [1, t, t^2, t^3] * M * [P[i-1], P[i], P[i+1], P[i+2]]
 */
vec3 catmullRomSpline(vec3 p0, vec3 p1, vec3 p2, vec3 p3, float t)
{
    vec3 c1,c2,c3,c4;

    c1 = p1;
    c2 = -0.5*p0 + 0.5*p2;
    c3 = p0 + -2.5*p1 + 2.0*p2 + -0.5*p3;
    c4 = -0.5*p0 + 1.5*p1 + -1.5*p2 + 0.5*p3;

    return (((c4*t + c3)*t + c2)*t + c1);
}

vec3 camPath(float t)
{
    // Capacity of path points table
    const int aNum = 8;

    // Loop to aNum
    t = fract(t/float(aNum))*float(aNum);

    // Segment number
    int segNum = int(floor(t));
    // Segment portion [0..1]
    float segTime = t - float(segNum);

    // Catmull-Rom spline needs surrounding control points,
    // so we're looping the path, making every point has enough neighbours.
    if (segNum == 0) return catmullRomSpline(camPathTable[aNum-1], camPathTable[0], camPathTable[1], camPathTable[2], segTime);
    if (segNum == aNum-2) return catmullRomSpline(camPathTable[aNum-3], camPathTable[aNum-2], camPathTable[aNum-1], camPathTable[0], segTime);
    if (segNum == aNum-1) return catmullRomSpline(camPathTable[aNum-2], camPathTable[aNum-1], camPathTable[0], camPathTable[1], segTime);

       return catmullRomSpline(camPathTable[int(segNum)-1], camPathTable[int(segNum)], camPathTable[int(segNum)+1], camPathTable[int(segNum)+2], segTime);
}

void main(void)
{

    vec2 u = (gl_FragCoord.xy - resolution.xy*0.5)/resolution.y;
    float speed = time * flightSpeed;
    setCamPath();

    vec3 ro = camPath(speed); // Camera position
    vec3 lk = camPath(speed + .5);  // Look At
    vec3 lp = camPath(speed + lightDistance); // Light position.

    // Camera vectors
    vec3 fwd = normalize(lk-ro);
    vec3 rgt = normalize(vec3(fwd.z, 0, -fwd.x));
    vec3 up = (cross(fwd, rgt));

    vec3 rd = normalize(fwd + FOV*(u.x*rgt + u.y*up));

    // Initiate the scene color to black.
    vec3 col = vec3(0);

    float t = trace(ro, rd);

    // Lighting is completely taken from Shane.
    if (t < fogDistance)
    {
        vec3 sp = ro + rd*t; // Surface position.
        vec3 sn = normal(sp); // Surface normal.
        vec3 ref = reflect(rd, sn); // Reflected ray.

        const float ts = 2.; // Texture scale.
        vec3 oCol = vec3(0.75);//tex3D(iChannel0, sp*ts, sn); // Texture color at the surface point.

        // Darker toned paneling.
        vec3 q = abs(mod(sp, 3.) - 1.5);
        if (max(max(q.x, q.y), q.z) < 1.063) oCol = oCol*darkColor;

        // Bringing out the texture colors a bit.
        oCol = smoothstep(0.0, 1.0, oCol);

        float sh = softShadow(sp, lp, 16.); // Soft shadows.
        float ao = calculateAO(sp, sn); // Self shadows.

        vec3 ld = lp - sp; // Light direction.
        float lDist = max(length(ld), 0.001); // Light to surface distance.
        ld /= lDist; // Normalizing the light direction vector.

        float diff = max(dot(ld, sn), 0.); // Diffuse component.
        float spec = pow(max(dot(reflect(-ld, sn), -rd), 0.), 12.); // Specular.
        //float fres = clamp(1.0 + dot(rd, sn), 0.0, 1.0); // Fresnel reflection term.

        float atten = 1.0 / (1.0 + lDist*0.25 + lDist*lDist*.1); // Attenuation.

        // Secondary camera light, just to light up the dark areas a bit more. It's here just
        // to add a bit of ambience, and its effects are subtle, so its attenuation
        // will be rolled into the attenuation above.
        diff += max(dot(-rd, sn), 0.)*.45;
        spec += pow(max(dot(reflect(rd, sn), -rd), 0.), 12.)*.45;

        // Based on Eiffie's suggestion. It's an improvement, but I've commented out,
        // for the time being.
        //spec *= curve(sp);

        // REFLECTION BLOCK.
        //
        // Cheap reflection: Not entirely accurate, but the reflections are pretty subtle, so not much
        // effort is being put in.
        float rt = refTrace(sp + ref*0.1, ref); // Raymarch from "sp" in the reflected direction.
        vec3 rsp = sp + ref*rt; // Reflected surface hit point.
        vec3 rsn = normal(rsp); // Normal at the reflected surface.

        vec3 rCol = vec3(1.0); // Texel at "rsp."
        q = abs(mod(rsp, 3.) - 1.5);
        if (max(max(q.x, q.y), q.z)<1.063) rCol = rCol*vec3(.7, .85, 1.);
        // Toning down the power of the reflected color, simply because I liked the way it looked more.
        rCol = sqrt(rCol);
        float rDiff = max(dot(rsn, normalize(lp-rsp)), 0.); // Diffuse at "rsp" from the main light.
        rDiff += max(dot(rsn, normalize(-rd-rsp)), 0.)*.45; // Diffuse at "rsp" from the camera light.

        float rlDist = length(lp - rsp);
        float rAtten = 1./(1.0 + rlDist*0.25 + rlDist*rlDist*.1);
        rCol = min(rCol, 1.)*(rDiff + vec3(.5, .6, .7))*rAtten; // Reflected color. Not accurate, but close enough.
        //
        // END REFLECTION BLOCK.

        // Combining the elements above to light and color the scene.
        col = oCol*(diff + vec3(.5, .6, .7)) + vec3(.5, .7, 1)*spec*2. + rCol*0.25;

        // Shading the scene color, clamping, and we're done.
        col = min(col*atten*sh*ao, 1.);

    }

    // Fadeout to a fog
    col = mix(col, fogColor, smoothstep(0., fogDistance - 15., t));

    // Last corrections
    col = pow(clamp(col, 0.0, 1.0), vec3(1.0 / Gamma));
    glFragColor = vec4(col, 1.0);

}
