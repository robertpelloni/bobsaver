#version 420

// original https://www.shadertoy.com/view/wdXfR2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

///////////Gyroid based on art of code tut
#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .01
float t,g=0.;

mat2 rot (float a)
    {return mat2(cos(a),sin(a),-sin(a),cos(a));} 

float    gyroid (vec3 p,float s){
        p *=s;
        float d = abs(dot (sin(p*0.9),cos(p.zxy*1.02))+1.7+(sin(t*.3)*.2))/(s*2.)-.03;
        return d;
    }

float sdf(vec3 p) {
    p.xy *= rot (p.z*.35);
    p.z +=t*.5;                        //move forward
       float d1 = gyroid(p,8.);    
     g += 0.1/(0.1+d1*d1*114.);        //add glow 
     return d1;
}

float RayMarch(vec3 ro, vec3 rd) {
    float dO=0.;
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        float dS = sdf(p);
        dO += dS*0.8;
        if(dO>MAX_DIST || dS<SURF_DIST) break;
    }
    
    return dO;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    t = mod(time,400.);            //stop time getting to big
    vec3 col = vec3(0.);
  
    vec3 ro = vec3(.2, 0.1, -3.);
    vec3 rd = normalize(vec3(uv.x, uv.y, (sin(t*.66)+1.)*.4)+.2);

    float d = RayMarch(ro, rd);
    
    vec3 p = ro + rd * d;
    float fog = length (ro-p);
  
    col =clamp (vec3(1.-p.z,p.y*.6,p.z+2.),0.,1.);
    col = mix(col,vec3(.1,.12,.3),1.-exp(-0.06*fog*fog));  //fog col
    col += g*.008*(p.z+2.);        //add glow more glow in dist        
    col = pow( col, vec3(0.4545) );        //gamma
    glFragColor = vec4(col,1.0);
}
