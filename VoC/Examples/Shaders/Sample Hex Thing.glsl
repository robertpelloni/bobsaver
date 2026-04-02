#version 420

// original https://www.shadertoy.com/view/NdfGRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Hex Tiling From "The Art of Code" tutorial
//Colors, movement, and flickering stuff is original
float remap(float a, float b, float c, float d, float t)
{
    return((t-a) / (b-a))* (d-c) + c;
}
float HexDist(vec2 p) {
    p = abs(p);
    float c = dot(p, normalize(vec2(1,1.73)));
    c = max(c,p.x);
    return c;
}

vec4 HexCoords(vec2 uv) 
{
    vec2 r = vec2(1., 1.73);
    vec2 h = r*.5;   
    vec2 a = mod(uv, r)-h;
    vec2 b = mod(uv-h, r)-h;  
    vec2 gv = dot(a,a)<dot(b,b) ? a : b;
    float x = atan(gv.x,gv.y);
    float y = .5-HexDist(gv);
    vec2 id = uv-gv;
    return vec4(gv.x, y, id.x, id.y);
}
void main(void)
{
    float t = time;
    t*=1.0;//Speed Adjustment
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec3 col = vec3(1);
    
    uv+=t/50.;
    uv *= 8.5;
    
    vec4 hc = HexCoords(uv);
    float c = smoothstep(.03, .04, hc.y);   
    float vary =remap(-.95,-.75,0.,1.,sin(t*3.+hc.z+hc.w))/2.;
    float c2=1.-smoothstep(.0+vary,vary,abs(hc.x));  
    c2*=smoothstep(.03, .04, hc.y*sin((hc.z+hc.w)+t/1.2));
    col+=min(c,c2);
    clamp(col,0.,1.);
    
    float r = remap(-1.,1.,0.,1.,sin(hc.z));
    float g = remap(-1.,1.,0.,1.,sin(hc.w));
    float b = remap(-1.,1.,0.,1.,sin(hc.w+hc.z)+remap(-1.,1.,-.25,.5,sin(t/2.)));
    col.rgb*=vec3(r,g,b)/2.;
    
    glFragColor = vec4(col,1.0);
}
