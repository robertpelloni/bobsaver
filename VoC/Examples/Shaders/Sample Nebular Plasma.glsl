#version 420

// original https://www.shadertoy.com/view/NlBBRt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash(in vec2 uv){
    return fract(sin(dot(uv, vec2(14.478473612, 53.252567))) * 37482.1);
}

vec2 hash2(in vec2 uv)
{
    vec3 o = fract(vec3(uv.yxx*893.335)*vec3(0.146651, 0.185677, 0.135812));
    o += dot(o.zxy, o.yzx+60.424);
    return fract((o.yx+o.zy)*o.xz);
}

float voronoi (in vec2 uv, in float zp, in float sd, in float sq, in float sz)
{ // Params;    UV coords   Z position     Seed        Squarify    Point size
    float sc = 4.; // base scale
    vec2 S = uv.xy*sc, // Scaled UV
         V = fract(S), // Cell UV
         Ib = floor(S)/sc; // Cell ID base
    float C = 0.; // Output collector
    for (float x = -1.; x <= 1.; x += 1.)
    {
        for (float y = -1.; y <= 1.; y += 1.)
        {
            vec2 I = Ib-vec2(x,y)/sc+sd; // Get ID of targeted cell then interpolate
            float R = zp+hash(I)*(hash(I+0.42424)*0.9+0.1);
            vec3 o = vec3(floor(R),ceil(R),cos(fract(R)*3.141592653589)/-2.+0.5);
            vec2 P = mix(mix(hash2(I+o.x),hash2(I+o.y),o.z),vec2(0.5),sq);
            
            float D = distance(P,V+vec2(x,y))-sz; // Find distance to point
            C = min(C,D); // Mix cell into color
        }
    }
    return C+sz;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    float scale = 2.1;
    float rescale = 1.2;
    float scalebright = 0.4;
    float m = 0., s = 0., h = 0., t = 0., cn = 0.;
    float vo1 = 0.;
    float vo2 = 0.;
    
    for (int i = 0; i < 8; i++) {
        m = float(i)/rescale+1.;
        s = float(i)*2.231+1.31354;
        h = 1./(float(i)/scalebright+1.);
        t = time*(float(i)/2.+1.)/4.;
        vo1 += voronoi((uv*m)/scale+hash2(vec2(float(i))+0.4443),t,s,0.,2.)*h;
        vo2 += voronoi((uv*m)/scale+hash2(vec2(float(i))+0.4443),t,s+0.4123,0.,2.)*h;
        cn += h;
    }
    
    vec3 col = vec3(vo1/cn) * vec3(1.0,0.5,0.0);
    col += vec3(vo2/cn) * vec3(0.0,0.5,1.0);
    col = clamp(pow(col,vec3(3.))*3.,0.,1.);
    
    glFragColor = vec4(col,1.0);
}
