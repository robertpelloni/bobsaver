#version 420

// original https://www.shadertoy.com/view/Nd2XD3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int MAX_RAY_STEPS = 64;

// sph intersect, credits iq
vec2 sphIntersect2( in vec3 ro, in vec3 rd, in vec4 sph)
{
    vec3 oc = ro - sph.xyz;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - sph.w*sph.w;
    float h = b*b - c;
    if( h<0.0 ) return vec2(-1.0,-1.0);
    h = sqrt( h );
    return vec2(-b - h, -b + h);
}

// credits anastadunbar
float rand(float co) { return fract(sin(co*(91.3458)) * 47453.5453); }
float rand(vec2 co){ return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453); }
float rand(vec3 co){ return rand(co.xy+rand(co.z)); }
float randrise(ivec3 co,float time){ return rand(vec3(co.x,co.y+int(time),co.z));}

//mine
float bubblesRising( vec3  rayDir, vec3  rayPos, 
                     float time)  
{
     
    float bubble = -time*2.0;
    float fbubble = fract(bubble);
    float ibubble = floor(bubble);
    // instead of offsetting the snow rise inside the voxel trace, we offset the ray
    vec3 offset = vec3(0,fract(bubble),0); 
    rayPos+=offset;
    vec3 orp = rayPos;
    // branchless voxel tracing initialization, credits fb39ca4 dda
    ivec3 mapPos = ivec3(floor(rayPos + 0.0));
    vec3 deltaDist = abs(vec3(length(rayDir)) / rayDir);
    ivec3 rayStep = ivec3(sign(rayDir));
    vec3 sideDist = (sign(rayDir) * (vec3(mapPos) - rayPos) + (sign(rayDir) * 0.5) + 0.5) * deltaDist; 
    bvec3 mask;
    float mist = 0.0;
    for (int i = 0; i < MAX_RAY_STEPS; i++) {            
            // branchless voxel tracing, credits fb39ca4 dda
            mask = lessThanEqual(sideDist.xyz, min(sideDist.yzx, sideDist.zxy));    
            sideDist += vec3(mask) * deltaDist;
            mapPos += ivec3(vec3(mask)) * rayStep;
            vec2 randomness = vec2(randrise(mapPos,floor(bubble)),ibubble);
            if(randomness.x>0.9)
                 {
                    // found a bubble in our voxel- where is it?
                    vec3 position=vec3(rand(vec2(mapPos.xz)),rand(vec2(mapPos.xz)+vec2(10203,2021)),rand(vec2(mapPos.xz)+vec2(121,-221)))*0.8 - 0.4;
                    // disable popping at max_ray_steps
                    float fade = smoothstep(0.0,10.0,float(MAX_RAY_STEPS-i))*0.1;
                    // offset snowflake to center, and randomize
                    vec3 msp = vec3(mapPos)+vec3(0.5,0.5,0.5)+position;
                    // intersect with sphere to get simple bubble- want to make this better
                    vec2 t = sphIntersect2(orp,rayDir,vec4(msp,(randomness.x-0.85)*1.5));
                    mist += abs(t.x-t.y) * fade;
                 }
    }             
    return mist;
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main(void)
{
    //camera setup, credits iq
    vec2 p = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec2 m =                mouse*resolution.xy.xy      /resolution.xy;
    vec3 ro = 4.0*normalize(vec3(sin(3.0*m.x), 0.8*m.y, cos(3.0*m.x))) - vec3(0.0,0.1,0.0);
    vec3 ta = vec3(0.0, -1.0, 0.0);
    mat3 ca = setCamera( ro, ta, 0.07*cos(0.25*time) );
    vec3 rd = ca * normalize( vec3(p.xy,1.5));

    vec3 col = vec3(0.0);
    float h=bubblesRising(rd, ro, time);
    if( h>0.0 )
    {
            col = mix( col, vec3(0.2,0.5,1.0), h );
            col = mix( col, 1.15*vec3(1.0,0.9,0.6), h*h*h );
    }
    col = sqrt( col )*1.3;
    glFragColor = vec4( col, 1.0 );
}
