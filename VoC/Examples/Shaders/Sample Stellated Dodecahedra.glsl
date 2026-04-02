#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/ttf3RS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// The four stellations of the dodecahedron:
// https://en.wikipedia.org/wiki/List_of_Wenninger_polyhedron_models#Stellations_of_dodecahedron
//
// Note that here they are raytraced, not raymarched. So a bunch of rays can be traced in a pixel,
// allowing here anti-aliasing, one shadow ray, and one specular reflection ray all summing to
// a total of 12 rays per pixel.
//

const float phi = (1. + sqrt(5.)) / 2.;
const float phi2 = phi + 1.; // == phi²
const float pi = acos(-1.);
const float outerAngle = 2. * pi / 5.;
const float innerAngle = 3. * pi / 5.;

// Pentagram shape mask
float pentagram(vec2 p, float incircleRadius, float rot)
{
    float r = incircleRadius / cos(outerAngle / 2.);
    float edgeLength = sin(outerAngle / 2.) * r;
    float r2 = incircleRadius + edgeLength / tan(innerAngle - pi / 2.);

    float a = -(floor((atan(p.y, p.x) - outerAngle / 4. + rot) / outerAngle) + .5) * outerAngle - outerAngle / 4. + rot;

    p = mat2(cos(a), sin(a), -sin(a), cos(a)) * p;
    p.y = abs(p.y);

    return step(p.x, mix(r2, incircleRadius, p.y / edgeLength));
}

// A stellated pentagon mask, which forms the polygonal face of one of the sides of
// a stellated dodecahedron. Note that the inner part is solid, but in the case of the 
// dodecahedron this is never visible anyway.
float stellatedPentagon(vec2 p, float incircleRadius, int stellation)
{
    float r = incircleRadius / cos(outerAngle / 2.);
    float edgeLength = sin(outerAngle / 2.) * r;
    float r2 = incircleRadius + edgeLength / tan(innerAngle - pi / 2.);
    float incircleRadius2 = r2 * cos(outerAngle / 2.);

    if(stellation == 3)
        return pentagram(p, incircleRadius2, -outerAngle / 2.);

    if(stellation == 2)
        p.y =- p.y;

    float a = -(floor((atan(p.y, p.x) - outerAngle / 4.) / outerAngle) + .5) * outerAngle - outerAngle / 4.;

    p = mat2(cos(a), sin(a), -sin(a), cos(a)) * p;

    if(stellation == 0)
        return step(p.x, incircleRadius);

    if(stellation == 1)
        return step(p.x, mix(r2, incircleRadius, abs(p.y) / edgeLength));

    if(stellation == 2)
        return step(p.x, incircleRadius2);
}

float intersectStellatedDodecahedron(vec3 ro, vec3 rd, inout vec3 nearN, out mat2x3 nearST, int stellation)
{
    // Points of initial pentagonal face
    vec3 a = vec3(+.5, 0, phi2 / 2.);
    vec3 b = vec3(-.5, 0, phi2 / 2.);
    vec3 c = vec3(0, phi2 / 2., + .5);
    vec3 d = vec3(-1, 1, 1) * phi / 2.;
    vec3 e = vec3(+1, 1, 1) * phi / 2.;

    // Make the great stellated dodecahedron smaller, for the sake of visualisation
    if(stellation == 3)
    {
        ro *= 2.;
        rd *= 2.;
    }
    
    vec3 faceCentre = (a + b + c + d + e) / 5.;

    float incircleRadius = cos(outerAngle / 2.) * distance(a, faceCentre);

    float invFaceHeight = 1. / (incircleRadius  + incircleRadius  / cos(outerAngle / 2.));

    float nearT = 1e4;
    bool hit = false;

    nearN = vec3(0);
    nearST = mat2x3(vec3(0), vec3(0));

    // The dodecahedron can be formed by 6 intersected slabs, much like how a parallelipiped
    // can be formed by 3 intersected slabs. In fact the dodecahedron can be formed
    // by 2 intersected parallelipipeds, and that's what I did here.
    
    for(int j = 0; j < 2; ++j)
    {
        for(int i = 0; i < 3; ++i)
        {
            vec3 faceCentre = (a + b + c + d + e) / 5.;

            // Intersect ray with the near plane of this slab
            
            vec3 n = cross(c - a, b - a);
            float w = dot(n, a);

            float dp = dot(rd, n);
            float si = -sign(dp);

            float t0 = (w * si - dot(ro, n)) / dp;

            vec3 rp = ro + rd * t0;

            // Make a tangent coordinate system for this face. This is used to
            // get UV coordinates for the polygon mask, and it's also used later for shading
            
            vec3 mvec = normalize(faceCentre);
            vec3 s = b - a;
            vec3 t = (c - (a + b) / 2.) * invFaceHeight * si;   
            vec2 uv = vec2(dot(rp - mvec, s), dot(rp - mvec, t));

            // Do a depth test and point-in-polygon test using the mask for the chosen
            // face polygon type
            
            if(t0 > 1e-4 && t0 < nearT && stellatedPentagon(uv, incircleRadius, stellation) > .5)
            {
                nearT = t0;
                nearN = n * si;
                nearST = mat2x3(s, t);
                hit = true;
            }

            // Rotate the pentagonal face so it lies in the plane of the next face
            // of the parallelipiped.
            
            a = a.yzx;
            b = b.yzx;
            c = c.yzx;
            d = d.yzx;
            e = e.yzx;
        }
        
        // The next parallelipiped is mirrored in the Y axis
        
        a.x = -a.x;
        b.x = -b.x;
        c.y = -c.y;
        d.y = -d.y;
        e.y = -e.y;
    }

    if(hit)
    {
        // An intersection was found
        nearN = normalize(nearN);
        return nearT;
    }

    return -1.;
}

float trace(vec3 ro, vec3 rd, out vec3 nearN, out mat2x3 nearST, int stellation)
{
    return intersectStellatedDodecahedron(ro, rd, nearN, nearST, stellation);
}

mat3 rotX(float a)
{
    return mat3(1., 0., 0.,
                0., cos(a), sin(a),
                0., -sin(a), cos(a));
}

mat3 rotY(float a)
{
    return mat3(cos(a), 0., sin(a),
                0., 1., 0.,
                -sin(a), 0., cos(a));
}

vec4 render(vec2 pos)
{    
    // Set up primary ray, including ray differentials
    
    vec2 p = pos / resolution.xy * 2. - 1.;
    p.x *= resolution.x / resolution.y;
    vec3 ro = vec3(0, -0, 5.7), rd = vec3(p, -2.);

    vec3 rdx = rd + dFdx(rd);
    vec3 rdy = rd + dFdy(rd);
    
    vec3 ld = normalize(vec3(1,1.5,.9));

    // Rotation transformation
    
    mat3 m = rotX(time / 4.) * rotY(time / 3.);

    ro = m * ro;
    rd = m * rd;
    rdx = m * rdx;
    rdy = m * rdy;
    ld = m * ld;

    vec3 nearN;
    mat2x3 nearST;

    // Alpha for shape transition
    
    float time = time + 1.;
    float phaseLength = 7.;
    float transitionLength = .2;
    float alpha = smoothstep(0., transitionLength, phaseLength / 2. - abs(mod(time, phaseLength) - phaseLength / 2.));

    int stellation = 1 + (int(floor(time / phaseLength)) % 3);

    // Trace primary ray
    float t0 = trace(ro, rd, nearN, nearST, stellation);

    if(t0 < 0.)
        return vec4(0);
    
    vec4 glFragColor = vec4(0);

    // Get intersection points and pixel footprint
    vec3 rp = ro + rd * t0;        
    vec2 uv = vec2(dot(nearST[0], rp), dot(nearST[1], rp));

    vec3 rpx = ro + rdx * dot(rp - ro, nearN) / dot(rdx, nearN);        
    vec2 uvx = vec2(dot(nearST[0], rpx), dot(nearST[1], rpx));

    vec3 rpy = ro + rdy * dot(rp - ro, nearN) / dot(rdy, nearN);         
    vec2 uvy = vec2(dot(nearST[0], rpy), dot(nearST[1], rpy));

    float uvscale = .5;

    // MIP level from footprint
    float lod = log2(max(length(uvx - uv), length(uvy - uv)) * 256. * uvscale);

    float ao = 1.;

    vec3 r = reflect(rd, nearN);

    // Some AO term
    if(stellation == 1)
        ao = smoothstep(1., 2., length(rp));
    if(stellation == 2)
        ao = smoothstep(1.1, 3., length(rp));
    if(stellation == 3)
        ao = smoothstep(.5, 2.2, length(rp));

    vec3 key = vec3(max(0., dot(nearN, ld))) * 1.3 * mix(.5, 1., ao);

    vec3 dummy;

    // Trace shadow ray for key light
    if(trace(rp, ld, dummy, nearST, stellation) > -1.)
        key *= 0.;

    vec3 fill = vec3(.35) * ao * mix(.5, 1., (.5 + .5 * (transpose(m) * nearN).y));

    float fresnel = mix(.2, .9, pow(clamp(1. - dot(-rd, nearN), 0., 1.), 2.));

    vec3 refl = vec3(0.0);//textureLod(iChannel1, r, 1.).rgb;

    // Trace reflection ray
    if(trace(rp, r, dummy, nearST, stellation) > -1.)
        refl *= .0;

    vec3 albedo = vec3(0.0);//textureLod(iChannel0, uv * uvscale, lod).rgb;

    glFragColor.rgb = mix(vec3(1), albedo, .9) * (key + fill);

    // Apply reflection with some gloss map
    glFragColor.rgb = mix(glFragColor.rgb, refl, clamp(fresnel * pow(max(0., albedo.b), 5.) * 3., 0., 1.));

    glFragColor.a = alpha;

    return glFragColor;
}

void main(void)
{
    glFragColor = vec4(0);

    vec3 backg = vec3(.07);

    // Anti-aliasing loop
    
    for(int y = 0; y < 2; ++y)
        for(int x = 0; x < 2; ++x)
        {
            vec4 r = render(gl_FragCoord.xy + vec2(x,y) / 2.);
            r.rgb = mix(backg, r.rgb, r.a);
            glFragColor.rgb += clamp(r.rgb, 0., 1.);
        }

    glFragColor /= 4.;

    // Gamma correction
    glFragColor.rgb = pow(glFragColor.rgb, vec3(1. / 2.2));
    glFragColor.a = 1.;
}

