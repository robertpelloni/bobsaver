#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3ldcWs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
A learning experience into shaders and raymarching.

Originally written to fit into a "playable" 4k executable.

Lots of things learned and copy pasted from: https://www.iquilezles.org/
Also used Leviathan 2.0 for the 4k, there's a lot learned from it and some code present: https://github.com/armak/Leviathan-2.0
*/

vec4 m;
vec2 v;

vec3 jeep;
vec3 frontWheelOffset = vec3(0.9, -0.4, -0.7);
vec3 rearWheelOffset = vec3(-0.9, -0.4, -0.7);

//These are used as constants
vec3 cFrontWheelOffset = vec3(0.9, -0.25, -0.7);
vec3 cRearWheelOffset = vec3(-0.9, -0.25, -0.7);

vec3 lightPos;

float PI = 3.1416;

float hash(float c){return fract(sin(dot(c, 12.9898)) * 43758.5453);}

//Rotation
mat3 rx(float a){return mat3(1.0,0.0,0.0,0.0,cos(a),-sin(a),0.0,sin(a),cos(a));}
mat3 ry(float a){return mat3(cos(a),0.0,sin(a),0.0,1.0,0.0,-sin(a),0.0,cos(a));}
mat3 rz(float a){return mat3(cos(a),-sin(a),0.0,sin(a),cos(a),0.0,0.0,0.0,1.0);}

//Smoothmin, can be used to "blend" 2 distancefields together smoothly
float opSmoothMin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

vec2 opUnion(vec2 d1, vec2 d2)
{
    //min(d1,d2);
    return (d1.x<d2.x) ? d1 : d2;
}

vec2 opSubtract(vec2 d1, vec2 d2)
{
    //max(-d1,d2);
    return ((-d1.x)>d2.x) ? -d1 : d2;
}

vec2 opIntersect(vec2 d1, vec2 d2)
{
    //max(d1,d2);
    return (d1.x>d2.x) ? d1 : d2;
}

//Slightly simplified original equation for HCR1: Countryside
float heightAt(float x)
{
    x*=1.5;
    x+=10.0;
    return (cos(x/10.0)*2.0 +
            +(cos(x+(sin(x*0.25)))*0.2*min(x*0.0015, 1.0f))
            +(cos(x*0.17+(sin(x*0.25)))*2.0*min(x*0.00075, 1.0f))
            +(cos(x*0.0952+(sin(x*0.15)))*2.0*min(x*0.00275, 1.0f))
            +(-1.0 + sin(x/30.0+cos(x/32.14))*4.0*min(x*0.00075, 1.0f)))
            *(0.5+x/2000.0);
}

float sdRoundBox(vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float sdPlane( vec3 p, vec3 n, float h )
{
  // n must be normalized
  return dot(p,n) + h;
}

float sdBox(vec3 p, vec3 b)
{
    return max(max(abs(p.x)-b.x,abs(p.y)-b.y),abs(p.z)-b.z);
}

float sdSphere(vec3 p, float r)
{
    return length(p) - r;
}

float sdCappedCylinder( vec3 p, float h, float r )
{
  vec2 d = abs(vec2(length(p.xy),p.z)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdCappedCylinderXZ( vec3 p, float h, float r )
{
  //p.x += 1.0-sin(PI*0.5-(r + p.y)*m.y*0.1);
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdCircle2D(vec2 p, vec2 c, float r)
{
    float m = 0.1+max(dot(normalize(p-c), normalize(vec2(1, -1))), 0.0)*1.9;
    return clamp(1.0-pow(1.0-(length(p-c)-r)*2.5, 0.075*m), 0.0, 1.0);
}

vec3 getMaterialColor(vec3 p, float material)
{
    int c=int(material);
    if (c==0) return mix(vec3(36.0, 212.0, 255.0)/255.0, vec3(161.0, 236.0, 255.0)/255.0, v.y); //Skycolor 
    if (c==1) return mix(vec3(98.0, 169.0, 0.0) / 255.0, vec3(173.0, 234.0, 81.0) / 255.0, pow(1.0-clamp(abs(p.z-4.0)/1.9, 0.0, 1.0), 0.1));    //Surface color
    if (c==2) return vec3(98.0 , 169.0, 0.0  ) / 255.0; //Guess I forgot to use this
    if (c==3) //Terrain (underground part)
    {
        //Texture some circles for this material
        vec2 q = mod(p.xy*0.5+0.5*5.0,5.0)-0.5*5.0;
        
        float d = sdCircle2D(q, vec2(0.1, 0.5), 0.3);
        d = max(d, sdCircle2D(q, vec2(1.5, -0.5), 0.25));
        d = max(d, sdCircle2D(q, vec2(-0.5, -1.5), 0.17));
        d = max(d, sdCircle2D(q, vec2(2.0, 1.5), 0.08));
        d = max(d, sdCircle2D(q, vec2(-2.0, 0), 0.05));
        
        //Repeat a few circle on edge of texture to simulate tiling
        d = max(d, sdCircle2D(q, vec2(0.5, -2.7), 0.08));
        d = max(d, sdCircle2D(q, vec2(0.5, 2.3), 0.08));
        
        d = max(d, sdCircle2D(q, vec2(2.8, -2.0), 0.08));
        d = max(d, sdCircle2D(q, vec2(-2.2, -2.0), 0.08));
        return vec3(63.0 , 50.0 , 34.0 ) / 255.0*(2.0-d);
    }
    if (c==4) return vec3(168.0, 0.0  , 0.0  ) / 255.0; //Jeep chassis
    if (c==5) return vec3(50.0 , 50.0 , 50.0 ) / 255.0; //Jeep tires
    if (c==6) return vec3(150.0, 150.0, 150.0) / 255.0; //Jeep rims
    if (c==7) return vec3(192.0, 74.0 , 81.0 ) / 255.0; //Bill: Clothes red
    if (c==8) return vec3(207.0, 191.0, 168.0) / 255.0*1.1; //Bill: Head
    if (c==9) return vec3(225.0, 211.0, 196.0) / 255.0*1.2; //Bill: Eyes

    return vec3(0,1,0);
}

float getMaterialReflectivity(float material)
{
    if (material==1.0) return 0.1; //Terrain, just a little to see the jeep from the ground
    if (material==4.0) return 0.2; //Jeep chassis
    if (material==6.0) return 0.4; //Jeep rims
    return 0.0;
}

float getMaterialSpecular(float material)
{
    if (material == 1.0) return 0.0; //No specular on terrain surface
    if (material >= 7.0) return 0.05; //Only minimal specular on bill
    
    return 1.0;
}

float materialAmbient(float material)
{
    if (material==3.0) return 0.65; //Terrain
    if (material==4.0) return 0.4; //Jeep chassis
    if (material==5.0) return 0.3; //Jeep tires
    return 0.2;
}

//This defines our whole scene content, it returns distance to a point in the world
vec2 map(vec3 p, bool shadowPass)
{
    vec2 d = vec2(100.0, 0.0);
    
    //Terrain
    if (!shadowPass)
    {
        //Terrain
        d = opIntersect(vec2(p.y - heightAt(p.x), 1.0),
                        vec2(-sdPlane(p, vec3(0.0, 0.0, 1.0), -2.0), 3.0));
        
        //Sky plane
        d = opIntersect(d, vec2(-sdPlane(p, vec3(0.0, 0.0, -1.0), 6.0), 3.0));
    }

    vec2 dfJeep = opUnion(vec2(100.0, 0.0),
                    vec2(
                        opSmoothMin(
                            opSmoothMin(
                                opSmoothMin(
                                    sdRoundBox((p-jeep)*rz(m.z), vec3(1.6, 0.3, 0.8),0.1), //Chassis
                                    sdRoundBox((p-(jeep + vec3(0.45, 0.6, 0.0)*rz(-m.z)))*rz(m.z-0.3), vec3(0.05, 0.25, 0.7),0.03), //Windscreen
                                    0.1),
                                sdRoundBox((p-jeep-vec3(-1.65,0.37,0)*rz(-m.z))*rz(m.z+0.7), vec3(0.1, 0.02, 0.65),0.065), //Spoiler
                                0.12),
                            sdRoundBox((p-jeep-vec3(1.05,0.4,0)*rz(-m.z))*rz(m.z-0.15), vec3(0.2, 0.1, 0.25),0.035), 0.05),    //Scoop
                            
                        4.0)
                    ); 
    //dfJeep = opSmoothMin(dfJeep, vec2(sdRoundBox((p-jeep-vec3(1.2,0.45,0)*rz(-m.z))*rz(m.z-0.2), vec3(0.2, 0.1, 0.25),0.035), 4.0); //Scoop
                        
    //Jeep: Interior
    dfJeep = opIntersect(dfJeep, vec2(-sdBox((p-jeep-vec3(-0.2,0.1,0)*rz(-m.z))*rz(m.z), vec3(0.6, 0.5, 0.7)), 5.0));
    
    //Bumper
    dfJeep = opUnion(dfJeep, vec2(sdRoundBox((p-jeep-vec3(0.0,-0.3,0)*rz(-m.z))*rz(m.z), vec3(1.7, 0.05, 0.85),0.1), 5.0));
    
    //Car wheels
    {
        vec3 q = p;
        //Wheels
        q.z = abs(q.z-jeep.z)+2.4;
        dfJeep = opIntersect(dfJeep, vec2(-sdCappedCylinder((q-(jeep + cFrontWheelOffset*rz(-m.z)))*rz(m.z-0.3), 0.55, 0.2), 5.0));
        dfJeep = opIntersect(dfJeep, vec2(-sdCappedCylinder((q-(jeep + cRearWheelOffset*rz(-m.z)))*rz(m.z-0.3), 0.55, 0.2), 5.0));
        
        //Wheel covers
        q.z = abs(p.z-jeep.z)+2.5;
        dfJeep = opUnion(dfJeep, vec2(sdCappedCylinder((q-(jeep + frontWheelOffset*rz(-m.z)))*rz(m.z-0.3), 0.5,0.2), 5.0));
        dfJeep = opUnion(dfJeep, vec2(sdCappedCylinder((q-(jeep +  rearWheelOffset*rz(-m.z)))*rz(m.z-0.3), 0.5,0.2), 5.0));
        
        //Rims
        dfJeep = opUnion(dfJeep, vec2(sdCappedCylinder((q-(jeep + frontWheelOffset*rz(-m.z)))*rz(m.z-0.3), 0.3,0.21), 6.0));
        dfJeep = opUnion(dfJeep, vec2(sdCappedCylinder((q-(jeep +  rearWheelOffset*rz(-m.z)))*rz(m.z-0.3), 0.3,0.21), 6.0));
    }
    
    //Seat
    dfJeep = opUnion(dfJeep, vec2(sdRoundBox((p-jeep-vec3(-0.6,0.15,0)*rz(-m.z))*rz(m.z-0.2), vec3(0.05, 0.4, 0.5),0.1), 5.0));
    
    //Now put together with scene
    d = opUnion(d, dfJeep);
    
    //Antenna
    d = opUnion(d, vec2(sdCappedCylinderXZ((p-(jeep + vec3(-1.2, 1.2, 0.4)*rz(-m.z)))*rz(m.z), 0.075,0.8), 5.0));
    
    //Bill himself
    //Torso
    float fd = opSmoothMin(
                    sdRoundBox((p-jeep-vec3(-0.15,0.3,0)*rz(-m.z))*rz(m.z-0.2), vec3(0.1, 0.45, 0.35),0.1),
                    sdSphere((p-jeep-vec3(-0.15,0.3,0)*rz(-m.z))*rz(m.z), 0.55),
                    0.2);
    fd = opSmoothMin(fd, sdSphere((p-jeep-vec3(0.05,0.67,-0.2)*rz(-m.z))*rz(m.z), 0.15), 0.1);
    fd = opSmoothMin(fd, sdSphere((p-jeep-vec3(0.05,0.67,0.2)*rz(-m.z))*rz(m.z), 0.15), 0.1);
    d = opUnion(d, vec2(fd, 7.0));
        
    //Head
    d = opUnion(d, vec2(sdSphere((p-jeep-vec3(-0.35,1.2,0)*rz(-m.z))*rz(m.z), 0.35), 8.0));
        
    //Nose
    d = opUnion(d, vec2(sdSphere((p-jeep-vec3(-0.05,1.2,0)*rz(-m.z))*rz(m.z), 0.125), 8.0));
        
    //Eyes
    d = opUnion(d, vec2(sdSphere((p-jeep-vec3(-0.125,1.3,0.12)*rz(-m.z))*rz(m.z), 0.12), 9.0));
    d = opUnion(d, vec2(sdSphere((p-jeep-vec3(-0.125,1.3,-0.12)*rz(-m.z))*rz(m.z), 0.12), 9.0));
        
    d = opUnion(d, vec2(sdSphere((p-jeep-vec3(-0.0,1.32,0.12)*rz(-m.z))*rz(m.z), 0.04), 5.0));
    d = opUnion(d, vec2(sdSphere((p-jeep-vec3(-0.0,1.32,-0.12)*rz(-m.z))*rz(m.z), 0.04), 5.0));
        
    //Hat
    vec2 dHat = opIntersect(vec2(sdSphere((p-jeep-vec3(-0.38,1.25,0)*rz(-m.z))*rz(m.z), 0.35), 7.0),
                            vec2(sdPlane((p-jeep-vec3(-0.38,1.25,0)*rz(-m.z))*rz(m.z), normalize(vec3(0.6,-1.0,0.0)), 0.1), 7.0));
        
    float hatCurve = min(pow(abs(4.0-p.z), 2.0), 1.0);
    dHat.x = opSmoothMin(dHat.x, sdRoundBox((p-jeep-vec3(-0.8+hatCurve,1.2-hatCurve*0.6,0)*rz(-m.z))*rz(m.z-0.5), vec3(0.2, 0.02, 0.24),0.02),0.07);
    d = opUnion(d,dHat);
    return d;
}

vec3 rhs(vec3 dir, float i)
{
    vec2 rnd = vec2(hash(i+1.), hash(i+2.));
    float s = rnd.x*PI*2.;
    float t = rnd.y*2.-1.;
    vec3 v = vec3(sin(s), cos(s), t) / sqrt(1.0 + t * t);
    return v * sign(dot(v, dir));
}

float ao( vec3 p, vec3 n, float maxDist, float falloff)
{
    float ao = 0.0;
    for( int i=0; i<10; i++ )
    {
        float l = hash(float(i))*maxDist;
        vec3 rd = normalize(n+rhs(n, l )*0.95)*l;
        ao += (l - map( p + rd, false).x) / pow(1.+l, falloff);
    }
    return clamp(1.-ao*0.1,0.0,999.0);
}

vec3 normal(vec3 p)
{
    // Copy from iq shader.
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    for( int i=0; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(p+0.0005*e, false).x;
    }
    return normalize(n);
}

//Raymarch soft shadows
float softshadow( vec3 ro, vec3 rd, float mint, float maxt, float k )
{
    float res = maxt;
    float ph = 1e20;
    for( float t=mint; t<maxt; )
    {
        float h = map(ro + rd*t, true).x;
        if( h<0.001 )
            return 0.0;

        float y = h*h/(2.0*ph);
        float d = sqrt(h*h-y*y);
        res = min( res, k*d/max(0.0,t-y) );
        ph = h;
        t += h*0.5+0.01;
    }
    return res;
}

//This goes forward until close enough to a surface
vec3 raymarch( vec3 ro, vec3 rd, out float material, const int iterationCount, const float step)
{
    vec3 p = ro;
    vec2 d;
    float t = .0;
    for(int i=0; i<iterationCount; i++)
    {
        d = map(p, false);
        if( d.x < 0.01)
        {
            material = d.y;
            break;
        }
        
        if (t > 100.0)
        {
            material = 0.0;
            return p;
        }
        
        t += d.x*step;
        p += rd*d.x*step;
    }
    material = d.y;
    return p;
}

vec3 shade(vec3 p, vec3 n, vec3 rd, float material)
{
    float light = 1.0;
    
    if (material > 0.0)
    {
        vec3 lightDir = normalize(lightPos-p);
        float lightPower = 1.0-length(lightPos-p)*0.0005;

        //Calculate shadows into our lighting
        float shadowMul = 0.5;
        if (material != 3.0)
            shadowMul = softshadow(p, normalize(lightPos-p), 0.1, 20.0 , 12.0);
                
        lightPower = lightPower*0.5f + shadowMul*0.5;
        lightPower = max(min(lightPower, 1.0), 0.0);
        
        float ambient = materialAmbient(material);
        
        //Calculate diffuse and specular light and ambient occlusion (specular only on jeep)
        float lightDiff = ambient + max(dot(n, lightDir), 0.0) * lightPower * 1.0 * ao(p, n, 2.0, 2.0)*0.7;
        
        float lightSpec = pow(max(dot(reflect(rd, n), lightDir), 0.0), 8.0) * getMaterialSpecular(material);
        light = (lightDiff + lightSpec);
    }
    return getMaterialColor(p, material) * light;
}

void main(void)
{
    vec2 q = gl_FragCoord.xy/resolution.xy;
    vec2 v = -1.0+2.0*q;
    v.x *= resolution.x/resolution.y;
    
    //Scale our input vector back to float
    m.x = time*5.0;// = vec4(inVec) / 44100.0;
    m.y = heightAt(m.x)+1.0;
    m.z = atan(heightAt(m.x-0.7) - heightAt(m.x+0.7));
    m.w = time*5.0;
    
    //Set jeep position from our input data
    jeep = vec3(m.x, m.y, 4.0);
    
    //Wheel suspension "simulation"
    vec3 wp = jeep + frontWheelOffset*rz(-m.z);
    if (heightAt(wp.x) < wp.y) frontWheelOffset.y = clamp(heightAt(wp.x) - wp.y, -0.8, -0.35) + 0.1;
    wp = jeep + rearWheelOffset*rz(-m.z);
    if (heightAt(wp.x) < wp.y) rearWheelOffset.y = clamp(heightAt(wp.x) - wp.y, -0.8, -0.35) + 0.1;

    //Camera position
    float zoom = 0.5+pow(abs(m.x - m.w)*0.07,1.7);
    vec3 ro = vec3(m.w,23.0*zoom,-30.0*zoom);
    
    //Camera rotation
    mat3 rot = rx(0.5)*ry(clamp((m.x - m.w)/30.0, -0.5, 0.5));
    
    //Calculate average terrain height to offset camera
    float h = 0.0;
    for (int i = 0; i < 20; i++)
    {
        h +=heightAt(-5.0+ro.x+float(i)*1.0);
    }
    h/=20.0;
    ro.y += h;
    ro += vec3( v.x, v.y, 0) * rot;
    vec3 rd = normalize(vec3(v.x, v.y, 7.0-abs(m.x - m.w)/4.0))*rot;
    
    //Define light position
    lightPos = vec3(ro.x+20.0, ro.y+20.0, 3.0);        

    float material;
    vec3 p = raymarch(ro, rd, material, 80, 0.7);
        
    vec3 col = getMaterialColor(p, material);
    vec3 n = normal(p);
    
    //Calculate Lighting with a single point light (only on pixels that are not sky or terrain)
    if (material > 0.0)
    {
        col = shade(p, n, rd, material);
        
        float refl = getMaterialReflectivity(material);
        //Add reflection
        if (refl > 0.0)
        {    
            float rMaterial;
            vec3 rrd = reflect(rd, n);
            vec3 rp = raymarch(p + n*0.05, rrd, rMaterial, 60, 1.0);
            vec3 rn = normal(rp.xyz);
            vec3 rColor = shade(rp, rn, rrd, rMaterial);
            
            col += rColor*refl;// * max(pJeep, pSurface*1.5);            
        }
    }

    glFragColor = vec4(col, 1);

}
