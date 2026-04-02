#version 420

// original https://www.shadertoy.com/view/Wt3XRN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

int mat;

mat2 rot(float a){
    return mat2(cos(a),-sin(a),
                sin(a),cos(a));
}
float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float map(vec3 p ){
    
    float ink = length((p))-1.;

    float gold = (length((p+vec3(0)))-2.);
   
    float b1 = sdBox(p,vec3(2.));

    p.xz*=rot(0.9);
   
    gold = max(-b1,sdBox(p,vec3(2.)));
    float outer1 = sdBox(p,vec3(20));
    p.yz*=rot(3.+time);

    float outer=max(-outer1,sdBox(p,vec3(21)));
    
    float best = min(outer,min(ink,gold));
    
    if(best == gold){
        mat=1;
    }else if(best ==ink){
        mat = 0;
    }else{mat = 2;}
    return best;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.x;
    vec3 ro = vec3(0,-0.2,-10);
    vec3 rd = normalize(vec3(uv,1));
    ro.zy*=rot(-0.1);
    rd.zy*=rot(-0.1);
    ro.zx*=rot(time/5.);
    rd.zx*=rot(time/5.);
    float tot = 0.;
    float dist = 0.;
    vec3 p;
    vec3 color = vec3(1);
    
    for(int i = 0; i<200;i++){
        p = ro+rd*tot;
        dist = map(p);
        tot+=dist;
        if(abs(dist)<0.0001){
            vec2 e = vec2(0.001,0.);
            vec3 n = normalize(vec3(map(p+e.xyy)-map(p-e.xyy),
                        map(p+e.yxy)-map(p-e.yxy),
                        map(p+e.yyx)-map(p-e.yyx)));
            if(mat == 0){
                float fresnel = pow(1.-dot(- rd,n),5.);
                color*=fresnel;
                ro = p+n*0.01;
                rd = reflect(rd,n);
                tot = 0.;

            } else if(mat == 1){
                color*=vec3(1.0,0.5,0.1);
                ro = p+n*0.1;
                rd = reflect(rd,n);
                tot = 0.;
            }else if(mat == 2){
                color*=vec3(0.5,0.4,0.5);
                ro = p+n*0.1;
                rd = reflect(rd,n);
                tot = 0.;
            }

        }
    }
   
                        
    
   
   
    color = pow(color,vec3(0.25));
    glFragColor = vec4(color,1.0);
}
