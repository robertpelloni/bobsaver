#version 420

// original https://www.shadertoy.com/view/tdXSDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fake holes in analytic plane.

const float pi = 3.1415926;
const float eps = 0.00001;
vec2 R;
vec2 rot(vec2 uv, float b){
    float a = atan(uv.y, uv.x);
    float r = length(uv);
    return vec2(r * cos(a + b), r * sin(a + b));
   
}

vec3 hsv( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return c.z * mix( vec3(1.0), rgb, c.y);
}
vec4 cm(vec3 p)
{
      return vec4(hsv(vec3(abs(p.z+p.x*2.) + time*0.8, 0.99, 0.95)), 1.0);
}

void main(void)
{
    vec2 u = gl_FragCoord.xy;

    R = resolution.xy;
    vec2 uv = (u - .5*R.xy)/R.y;
    vec2 ouv = u / R;
    vec2 m = vec2(mouse*resolution.xy.xy / R) - 0.5;
    m.x *= R.x / R.y;
    
 
    vec3 rd = normalize(vec3(uv, 1.0 - dot(uv, uv) * 0.7));
    vec3 cmd = normalize(vec3(uv, 1.0 - dot(uv, uv) * 0.7));
    
   
    
     rd.xz = rot(rd.xz, 0.584);
    cmd.xz = rot(rd.xz, 0.045);
    
    vec4 col;
    
    vec3 n = normalize(vec3(0.0, 1.0, 0.0));
    vec3 P = vec3(0.0, -0.25, 0.0);
    //vec3 P = vec3(0.0, -0.15, 0.0);
    vec3 h;
    vec3 ref;
    float sp = time*.4;
    
    float d = dot(rd, n);
    
    if(abs(d) > eps)
    {
        float t = dot(P, n) / d; 
        
        if(t >= eps){
            h = rd * t;
            ref = reflect(h,rd);
            col = cm(ref);
        }
        else{
            h = rd * -t;
            ref = reflect(h, rd);
            col = cm(ref);
        }
        
        // Hole stuff
        vec3 hp = 4.0 * (vec3(-4.0, -(P.y / 2.0), -sp) - h);
        
        hp.x*=2.6;
        hp.z*=2.4;
        
        hp = mod(hp, vec3(5., 1., 5.))-1.0 ;
       
        vec3 dHx = hp - h*0.6;
        
        float hole = smoothstep(0.98, 1.0, length(hp));
        
        vec3 lp2 = vec3(0.4, 0.0, 1.0)*0.9;
        float  dif = max(dot(h,lp2), 0.0);
        
        col *= dif;
        
        // Fake holes
        float sh = smoothstep(1.0, 0.99, length(dHx));
        col = mix(mix(col,cm(rd), sh)*sh, col, hole);
        // Fog
        col *= smoothstep(8.0, -2.0, abs(t));
        col = mix(cm(cmd),col ,smoothstep(8.0, 0.0, abs(t)));
    }
    
    glFragColor = col;
}

