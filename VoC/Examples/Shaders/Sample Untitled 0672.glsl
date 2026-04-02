#version 420

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

const int   complexity      = 16;    // More points of color.
const float fluid_speed     = 140.0;  // Drives speed, higher number will make it slower.
  mat2 rotate2d(float theta) 
{
  float s = sin(theta), c = cos(theta);
  return mat2(c, -s, s, c);
}
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}
vec4 TriGrid(vec2 uv, out vec2 id)
{
    uv *= mat2(1,-1./1.73, 0,2./1.73);
    vec3 g = vec3(uv,1.-uv.x-uv.y);
    vec3 _id = floor(g)+0.5;
    g = fract(g);
    float lg = length(g);
    if (lg>1.)
        g = 1.-g;
    vec3 g2 = abs(2.*fract(g)-1.);                  // distance to borders
    vec2 triuv = (g.xy-ceil(1.-g.z)/3.) * mat2(1,.5, 0,1.73/2.);
    float edge = max(max(g2.x,g2.y),g2.z);
    id = _id.xy;
    id*= mat2(1,.5, 0,1.73/2.); // Optional, unskew IDs
    id.xy += sign(lg-1.)*0.1; // Optional tastefully adjust ID's
    return vec4((1.0-edge)*0.43,length(triuv),triuv);
}

void main()
{
  vec2 p=(2.0*gl_FragCoord.xy-resolution)/max(resolution.x,resolution.y);
    
     vec2 id;
        vec4 h;
    
    vec3 pp = vec3(p,0.0);
    //p.x = sin(dot(p,p)+p.y*1.16);
    p *= rotate2d(sin(length(p)*2.5+time*0.15)*0.3);
     h = TriGrid(p*13.0, id);    
    //p*=0.85+sin(length(p*1.3)+time)*0.25;
    p.x += sin(time*0.1+p.y*3.31)*0.05;
    p.y += sin(time*0.3+p.x*14.0)*0.035;
    float vv = 0.0;
    float vv2 = 0.0;
  for(int i=1;i<complexity;i++)
  {
      p.x += sin(length(p*3.4)+p.y)*0.2;
      p.y += sin(p.x)*0.1;
    vec2 newp=p*.995;
    newp.x+=0.6/float(i)*sin(float(i)*p.y*1.1+time/fluid_speed*float(i+41)) + 0.5;
    newp.y+=0.6/float(i)*sin(float(i)*p.x*0.7+time/fluid_speed*float(i+14)) - 0.5;
    p=newp;
      p.y += sin(p.x*3.0+time*0.4)*0.005;
      p.x += sin(p.x*4.4+p.y+7.131+time)*0.006;
      vv+=sin(p.x-p.y*5.3)*0.33;
      vv2+=cos(p.y+p.x*(.3+float(i)*0.56))*0.05;
  }
    vec3 col = vec3(0.5/vv*5.1,0.05/vv2*1.45,vv2*4.4);
    if (col.g > 0.0)
    {
        col.b = 0.0;
        col.r = 0.0;
    }
    float d1 = length(col*col);
    d1=pow(2.0/d1,.53);
    col = vec3(d1*0.3,d1*0.15,d1*0.23)*1.5;
    //float zz = 0.5+sin(time*0.41)*0.5;
    //zz = 20.0+(zz*12.0);
    //col += vec3(length(sin(pp*zz))*0.4);
    
    col = clamp(col,vec3(0.0),vec3(1.0));
    float vv1 = smoothstep(0.0, 0.255, h.x);    
    col = mix(col,vec3(0.0),vv1);
    
    
  glFragColor=vec4(col, 1.0);
}
