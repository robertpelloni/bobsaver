#version 420

// original https://www.shadertoy.com/view/fsByDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
float fovzoom = .4;

vec2 rotate(in vec2 uv, float r){
    float s=sin(r);
    float c=cos(r);
    return uv*mat2(c,-s,s,c);
}

float hash(vec2 p) {
    p  = 50.0*fract( p*0.3183099 + vec2(0.71,0.113));
    return -1.0+2.0*fract( p.x*p.y*(p.x+p.y) );
}
float noise( in vec2 p ){
    vec2 i = floor( p );
    vec2 f = fract( p );
    
    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( hash( i + vec2(0.0,0.0) ), 
                     hash( i + vec2(1.0,0.0) ), u.x),
                mix( hash( i + vec2(0.0,1.0) ), 
                     hash( i + vec2(1.0,1.0) ), u.x), u.y);
}

void main(void)
{
    // Normalized pixel coordinates (from -1 to 1)
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    float rot = smoothstep(-.006,.006,sin(.1*time+4.))*PI*.5;
    uv=rotate(uv,rot);
    
    //Calculate render parameters
    vec3 camPos = vec3(.1*cos(8.*time)*.07,sin(time)*.07,-1.),
    f = normalize(-camPos),
    u = vec3(0,1,0),
    r = cross(f,u),
    sCenter = camPos+f*fovzoom,
    screenPoint = sCenter + uv.x * r + uv.y * u,
    rayDir = normalize(screenPoint-camPos);
    
    //Raymarch
    vec3 ray;
    float rayL, rayStep;   
    for (int i=0; i<250; ++i){
        ray = camPos + rayDir * rayL;
        rayStep = min(
        abs(ray.x-1.),
        abs(ray.x+1.));
        if(rayStep<.001) break;
        rayL += rayStep;
    }
    
    //Calculate wall UVs
    vec3 col = .6+.5*cos(time+uv.xyx+vec3(0,2,4));
    vec2 oUV = vec2(0);
    vec3 mask;
    if(rayStep<.001){
        //Ray hit wall
        oUV.x = ray.z;
        oUV.y = ray.y+step(ray.x,0.)*33.1;
        oUV.x+=time*8.;
        vec3 wallCol=vec3(.5+.5*sin(oUV.y*9.+5.*cos(.2*time)*2.)*
        .5+.5*sin(oUV.y*9.+19.*sin(.1*time)*2.)*
        .4+.4*(sin(oUV.x*2.5+noise(oUV)*2.)));
        wallCol*=wallCol;
        wallCol=mix(vec3(noise(oUV*2.5)),wallCol, .5+.5*sin(.23*time));
        wallCol*=col*min(6.*abs(uv.x),1.);
        col=mix(col, wallCol,
            min(7.*abs(uv.x),1.));
    } 
      

    // Output to screen
    glFragColor = vec4(col,1.0);
}
