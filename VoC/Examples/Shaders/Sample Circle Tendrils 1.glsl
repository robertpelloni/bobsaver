#version 420

// original https://www.shadertoy.com/view/4dKfDW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
float simplex(vec3 v){ 
  const vec2  C = vec2(1.0/6.0, 1.0/3.0);
  const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);
  vec3 i  = floor(v + dot(v, C.yyy));
  vec3 x0 =   v - i + dot(i, C.xxx);
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min(g.xyz, l.zxy);
  vec3 i2 = max(g.xyz, l.zxy);
  vec3 x1 = x0 - i1 + 1.0 * C.xxx;
  vec3 x2 = x0 - i2 + 2.0 * C.xxx;
  vec3 x3 = x0 - 1. + 3.0 * C.xxx;
  i = mod(i, 289.0); 
  vec4 p = permute(permute(permute(i.z+vec4(0,i1.z,i2.z,1))+i.y+vec4(0,i1.y,i2.y,1))+i.x+vec4(0,i1.x,i2.x,1));
  float n_ = 1.0/7.0;
  vec3  ns = n_ * D.wyz - D.xzx;
  vec4 j = p - 49.0 * floor(p * ns.z *ns.z);
  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_ );
  vec4 x = x_ *ns.x + ns.yyyy;
  vec4 y = y_ *ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);
  vec4 b0 = vec4( x.xy, y.xy );
  vec4 b1 = vec4( x.zw, y.zw );
  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));
  vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy;
  vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww;
  vec3 p0 = vec3(a0.xy,h.x);
  vec3 p1 = vec3(a0.zw,h.y);
  vec3 p2 = vec3(a1.xy,h.z);
  vec3 p3 = vec3(a1.zw,h.w);
  vec4 norm = 1.0/sqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;
  vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot(m*m, vec4(dot(p0,x0), dot(p1,x1), dot(p2,x2), dot(p3,x3)));
}

void main(void)
{
    float col = 0.0;
    for(int i = 0; i < 30; i++)
    {
        // coordinates
        vec2 uv = -1.0+2.0*gl_FragCoord.xy/resolution.xy;
        uv.x *= resolution.x/resolution.y;
        
        float scale = 3.0+3.0*pow(0.5+0.5*cos(time*0.41),2.0);
        uv *= pow(1.015+mix(0.03, 0.0, scale/10.0), float(i));
        float rf = length(fwidth(uv));
        
        uv+=time*0.02;
        
        // rotate
        float a = (time)*0.19;
        uv *= mat2(cos(a),sin(a),-sin(a),cos(a));

        // zoom
        uv *= scale;

        // repeat & pattern
        float repeat = 1.75+1.25*(0.5+0.5*sin(1.0+time*0.61));
        float r = pow(0.5+0.5*simplex(vec3( round(0.5+uv/repeat)*(1.0/scale), 0.05*float(i)+time*0.77)),3.0);
        uv = mod(uv,repeat)-repeat/2.0;

        float aa = 1.8*scale*rf*sqrt(r);
        
        float shape = pow(uv.x,2.0)+pow(uv.y,2.0);
        col += (smoothstep(r-aa,r, shape)-smoothstep(r,r+aa, shape))/(pow(float(1+i),1.0));        
    }
    
    glFragColor = vec4(pow(col, 1.0/2.2));
}
