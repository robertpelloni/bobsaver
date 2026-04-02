#version 420

// original https://www.shadertoy.com/view/DtcczX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// The box intersection code is based on the iq's. https://www.shadertoy.com/view/ld23DV
#define Rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))
#define antialiasing(n) n/min(resolution.y,resolution.x)
#define S(d,b) smoothstep(antialiasing(1.5),b,d)
#define B(p,s) max(abs(p).x-s.x,abs(p).y-s.y)
#define deg45 .707
#define R45(p) (( p + vec2(p.y,-p.x) ) *deg45)
#define Tri(p,s) max(R45(p).x,max(R45(p).y,B(p,s)))
#define SymdirY(p) mod(floor(p).y,2.)*2.-1.
#define BOX_NUM 27.

float cubicInOut(float t) {
  return t < 0.5
    ? 4.0 * t * t * t
    : 0.5 * pow(2.0 * t - 2.0, 3.0) + 1.0;
}

float getTime(float t, float duration){
    return clamp(t,0.0,duration)/duration;
}

float getAnimatedRotValue(float delay){
    float frame = mod(time,9.0+delay)-delay;
    float time = frame;
    float duration = 0.7;
    float rotVal = 0.0;
    if(frame>=1. && frame<3.){
        time = getTime(time-1.,duration);
        rotVal = cubicInOut(time)*90.;
    } else if(frame>=3. && frame<5.){
        time = getTime(time-3.,duration);
        rotVal = 90.+cubicInOut(time)*90.;
    } else if(frame>=5. && frame<7.){
        time = getTime(time-5.,duration);
        rotVal = 180.+cubicInOut(time)*90.;
    } else if(frame>=7. && frame<9.){
        time = getTime(time-7.,duration);
        rotVal = 270.+cubicInOut(time)*90.;
    }
    
    return rotVal;
}

// https://iquilezles.org/articles/boxfunctions
vec4 iBox( in vec3 ro, in vec3 rd, in mat4 txx, in mat4 txi, in vec3 rad ) 
{
    // convert from ray to box space
    vec3 rdd = (txx*vec4(rd,0.0)).xyz;
    vec3 roo = (txx*vec4(ro,1.0)).xyz;

    // ray-box intersection in box space
    vec3 m = 1.0/rdd;
    vec3 n = m*roo;
    vec3 k = abs(m)*rad;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    float tN = max(max(t1.x,t1.y),t1.z);
    float tF = min(min(t2.x,t2.y),t2.z);
    
    // no intersection
    if( tN>tF || tF<0.0 ) return vec4(-1.0);

    vec4 res = vec4(tN, step(tN,t1) );
    
    // add sign to normal and convert to ray space
    res.yzw = (txi * vec4(-sign(rdd)*res.yzw,0.0)).xyz;

    return res;
}

mat4 rotationAxisAngle( vec3 v, float angle )
{
    float s = sin( angle );
    float c = cos( angle );
    float ic = 1.0 - c;

    return mat4( v.x*v.x*ic + c,     v.y*v.x*ic - s*v.z, v.z*v.x*ic + s*v.y, 0.0,
                 v.x*v.y*ic + s*v.z, v.y*v.y*ic + c,     v.z*v.y*ic - s*v.x, 0.0,
                 v.x*v.z*ic - s*v.y, v.y*v.z*ic + s*v.x, v.z*v.z*ic + c,     0.0,
                 0.0,                0.0,                0.0,                1.0 );
}

mat4 translate( float x, float y, float z )
{
    return mat4( 1.0, 0.0, 0.0, 0.0,
                 0.0, 1.0, 0.0, 0.0,
                 0.0, 0.0, 1.0, 0.0,
                 x,   y,   z,   1.0 );
}

float truchetGraphic(vec2 p, float dir){
    vec2 prevP = p;
    p.x*=dir;
    p*=Rot(radians(45.));
    p.x = abs(p.x)-0.212;
    
    p*=Rot(radians(45.));
    vec2 prevP2 = p;
    float a = radians(45.);
    float d = abs(max(-dot(p+vec2(0.095),vec2(cos(a),sin(a))),B(p,vec2(0.15))))-0.03;
    p+=vec2(0.085);
    p*=Rot(radians(45.));
    d = max(-B(p,vec2(0.03,0.003)),d);
    
    p = prevP2;
    p+=vec2(0.105);
    
    p*=Rot(radians(45.));
    p.x = abs(p.x)-0.075;
    d = max(-B(p,vec2(0.007)),d);
    
    p = prevP;
    p = mod(p,0.03)-0.015;
    float d2 = length(p)-0.0005;
    d = min(d,d2);
    
    p = prevP;
    
    p.y*=dir;
    p*=Rot(radians(45.));
    float sdir = SymdirY(p);
    p.x*=1.7;
    p.y+=time*0.1*sdir;
    p.y = mod(p.y,0.08)-0.04;
    p.y*=sdir*-1.;
    d2 = Tri(p,vec2(0.015));
    d = min(d,d2);
    
    p = prevP;
    p.x*=dir;
    p*=Rot(radians(135.));
    p.y = abs(p.y)-0.17;
    p*=Rot(radians(45.));
    d2 = min(B(p,vec2(0.0005,0.01)),B(p,vec2(0.01,0.0005)));
    d = min(d,d2);
    
    return d;
}

float ui(vec2 p){
    vec2 prevP = p;
    p = mod(p,0.06)-0.03;
    float d = min(B(p,vec2(0.0001,0.006)),B(p,vec2(0.006,0.0001)));
    p = prevP;
    d = max(B(p,vec2(0.55,0.3)),d);
    
    p.x = abs(p.x)-0.7;
    vec2 prevP2 = p;
    float a = radians(-50.);
    p.y = abs(p.y)-0.2;
    float d2 = abs(max(-dot(p,vec2(cos(a),sin(a))),B(p,vec2(0.08,0.4))))-0.0001;
    p = prevP2;
    d2 = max(p.x-0.05,min(B(p-vec2(-0.08,0.0),vec2(0.003,0.03)),d2));
    d = min(d,d2);
    
    p = prevP2;
    p.y = abs(p.y)-0.35;
    p*=Rot(radians(50.));
    d2 = B(p,vec2(0.0001,0.15));
    d = min(d,min(B(p,vec2(0.003,0.05)),d2));
    
    p = prevP;
    p.x = abs(p.x)-0.56;
    p.y = abs(p.y)-0.42;
    p.x = abs(p.x)-0.012;
    d2 = abs(length(p)-0.008)-0.0003;
    d = min(d,d2);
    
    p = prevP;
    p.y = abs(p.y)-0.46;
    p.y*=-1.;
    d2 = abs(Tri(p,vec2(0.02)))-0.0005;
    d = min(d,max(-(p.y+0.016),d2));
    
    p = prevP;
    p.x = abs(p.x)-0.75;
    p.y = mod(p.y,0.018)-0.009;
    d2 = B(p,vec2(0.015,0.001));
    d2 = max(abs(prevP.y)-0.05,d2);
    d = min(d,d2);
    
    return d;
}

void main(void)
{
    vec2 p = (gl_FragCoord.xy-0.5*resolution.xy) / resolution.y;
    vec2 m =  mouse*resolution.xy.xy/resolution.xy;
    
    // camera movement    
    float an = radians(90.);
    vec3 ro = vec3( 2.5*cos(an), 0., 2.5*sin(an) );
    
        ro.yz *= Rot(radians(5.0));
        
        float delay = 2.5;
        float frame = mod(time,11.0+delay)-delay;
        float time = frame;
        
        float duration = 0.7;
        float rotVal = 0.0;
        if(frame>=1. && frame<3.){
            time = getTime(time-1.,duration);
            rotVal = cubicInOut(time)*90.;
        } else if(frame>=3. && frame<5.){
            time = getTime(time-3.,duration);
            rotVal = 90.+cubicInOut(time)*90.;
        } else if(frame>=5. && frame<7.){
            time = getTime(time-5.,duration);
            rotVal = 180.+cubicInOut(time)*90.;
        } else if(frame>=7. && frame<9.){
            time = getTime(time-7.,duration);
            rotVal = 270.+cubicInOut(time)*90.;
        } else if(frame>=9.){
            time = getTime(time-9.,duration+0.5);
            rotVal = 360.-cubicInOut(time)*360.;
        }
        
        ro.xz *= Rot(radians(-rotVal));
    
    vec3 ta = vec3( 0.0, 0.,0.0 );
    
    // camera matrix
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
    
    // create view ray
    vec3 rd = normalize( p.x*uu + p.y*vv + 1.8*ww );

    // raytrace
    float tmin = 10000.0;
    vec3 nor = vec3(0.0);
    vec3 pos = vec3(0.0);
    float oid = 0.0;
    mat4 txxRef = mat4(0.0);
    float dir = 0.0;
    
    float dist = .3;
    for(float i = 0.; i<BOX_NUM; i+=1.){
        int index = int(i);

        float x = dist-(float(mod(i,3.))*dist);
        float y = dist-(floor(mod(i,9.)/3.)*dist);
        float z = dist-(floor(i/9.)*dist);

        float rotVal = getAnimatedRotValue(i*0.15);
        mat4 rot = rotationAxisAngle( normalize(mod(i,2.) ==0.?vec3(1.0,0.0,0.0):vec3(0.0,1.0,0.0)), radians(rotVal) );
        
        mat4 tra = translate( x, y, z );
        mat4 txi = tra * rot; 
        mat4 txx = inverse( txi );
        
        vec4 res = iBox( ro, rd, txx, txi, vec3(0.15) );
        if( res.x>0.0 && res.x<tmin  ) { 
            tmin = res.x; 
            nor = res.yzw;
            oid = i;
            txxRef = txx;
            
            dir = 1.;
            if(mod(i,5.) == 0.)dir = -1.;
        }
    }

    vec3 col = vec3(0.) ;

    if( tmin<100.0 )
    {
        pos = ro + tmin*rd;
        
        // materials
        float occ = 1.0;
        vec3 mate = vec3(1.0);
        
        for(float i = 0.; i<BOX_NUM; i+=1.){
            int index = int(i);
            if(oid == i){
                vec3 opos = (txxRef*vec4(pos,1.0)).xyz;
                vec3 onor = (txxRef*vec4(nor,0.0)).xyz;

                vec3 colXZ = mix(col,vec3(1.),S(truchetGraphic(opos.xz,dir),0.0));
                vec3 colYZ = mix(col,vec3(1.),S(truchetGraphic(opos.yz,dir),0.0));
                vec3 colXY = mix(col,vec3(1.),S(truchetGraphic(opos.xy,dir),0.0));
                mate = colXZ*abs(onor.y)+colXY*abs(onor.z)+colYZ*abs(onor.x);
             }
        }
        
        // lighting
        vec3 lig = normalize(vec3(0.8,2.4,3.0));
        float dif = clamp( dot(nor,lig), 0.0, 1.0 );
        vec3 hal = normalize(lig-rd);
        
        float amb = 0.6 + 0.4*nor.y;
        float bou = clamp(0.3-0.7*nor.y,0.0,1.0);
        float spe = clamp(dot(nor,hal),0.0,1.0);
        col  = 4.0*vec3(1.00,0.80,0.60)*dif;
        col += 2.0*vec3(0.20,0.30,0.40)*amb;
        col += 2.0*vec3(0.30,0.20,0.10)*bou;
        col *= mate;                      
    } else {
        float d = ui(p);
        col = mix(col,vec3(0.7),S(d,0.0));
    }
    
    // gamma
    col = pow( col, vec3(0.45) );

    glFragColor = vec4( col, 1.0 );
}