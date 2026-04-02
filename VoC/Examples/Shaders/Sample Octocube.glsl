#version 420

// original https://www.shadertoy.com/view/sdjXzm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// 3 cubes and 4 spheres rotating 
// Thx to IQ, Flopine, Evvvvil. My Teachers
// Greetings: Fubu, JosSs, Napalm, duhow :3, Bran

mat2 rot (float a) { return mat2(cos(a),sin(a),-sin(a),cos(a));}

vec3 col = vec3 (0.4);
float shade = 0., st= 64., pres=0.01; 
bool hit = false;

#define PI acos(-1.)

float box_point (vec3 p, vec3 size)
{
    vec3 q = abs(p);
    return length(q-size);
}

float box (vec3 p, vec3 size)
{
    vec3 q = abs(p) - size;
    return length(max(q,0.0));
}

float sph (vec3 p, float r)
{
    return length(p)-r;
}

float SDF(vec3 p){
    vec3 po = p;
    float r = 1.0;
    
    p.xz*= rot (time);
    p.xy*= rot (time);
    
    vec3 p_rot= p;
    //r = sph(p,0.1);
    for (float i=0.f; i< 10.f; ++i) {
    p_rot.xy*= rot (0.5*time);
    r = min(r,box_point (p_rot,vec3(0.1*i+0.1*sin(3.0*time-0.2*i))));
    }
    r = min(r,box(p,vec3(0.3)));
    p.y += 0.3;
    r = min(r,sph(p,0.2));
    p.y -= 0.6;
    r = min(r,sph(p,0.2));
    p.y += 0.3;p.x += 0.3;
    r = min(r,sph(p,0.2));
    p.x -= 0.6;
    r = min(r,sph(p,0.2));
    p.x += 0.3; p.z +=0.25;
    p.xy*=rot(3.0*time);p.yz*=rot(PI/4.);p.xz*=rot(PI/4.);
    r = min(r,box(p,vec3(0.1)));
    p= po;
    p.xz*= rot (time);
    p.z -=0.3;
    p.xy*=rot(3.0*time);p.yz*=rot(PI/4.);p.xz*=rot(PI/4.);
    r = min(r,box(p,vec3(0.1)));
    
    return r;
}

void main(void)
{
    vec2 uv = vec2(gl_FragCoord.xy.x / resolution.x, gl_FragCoord.xy.y / resolution.y);
    uv -= 0.5;
    uv /= vec2(resolution.y / resolution.x, 1);

    vec3 ro = vec3(0.0,0.,-3);
    vec3 rd = normalize(vec3(uv,1.0));
    vec3 rp = ro;
    float r = 0.0;
    for (float i=0.f; i<st;++i)
    {
       r = SDF(rp);
      if (r < pres)
      {
        hit =true;
        shade=i/st;
         break;
      }
      rp += rd*r;
    }    
    
    if (hit) col = vec3(sqrt(1.0-shade));
    glFragColor = vec4(col,1.0);
}
