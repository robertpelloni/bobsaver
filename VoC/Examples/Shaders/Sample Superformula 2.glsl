#version 420

// original https://www.shadertoy.com/view/Ml3SzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.1415926;
float scale = 9.8;

float function(float r, float t,float y, float z, float n1, float a, float b, float n2, float n3);
float solve(vec2 p,float y, float z, float n1, float a, float b, float n2, float n3);
float value(vec2 p, float size, float y, float z, float n1, float a, float b, float n2, float n3);

void main(void)
{
    float width = 1. / min( resolution.x, resolution.y );
    vec2 control = resolution.xy*.5;
    
    vec2 uv = (gl_FragCoord.xy - control) * 1. * width;
    vec3 col = vec3(0.);
    float tf = floor(sin(time)*11.);
    
    col.rgb += 1. - smoothstep(.001,.002,abs(uv.x));
    col.rgb += 1. - smoothstep(.001,.002,abs(uv.y));
     
    
    uv -= vec2(0.35,0.25);
    float sf1 = value(uv*scale, width*scale,tf+.5,tf+.5,1.,1.,1.,1.,1.);
    col.rgb += 3.*smoothstep(.01,3.,sf1);
    
    uv -= vec2(-0.8,0.);
    float sf2 = value(uv*scale, width*scale,tf,tf,1.,1.,1.,1.,1.);    
    col.rgb += 3.*smoothstep(.01,3.,sf2);
    
    uv -= vec2(0.8,-0.5);
    float sf3 = value(uv*scale, width*scale,5.,tf,12.,12.,tf,1.,-1.5);    
    col.rgb += 3.*smoothstep(.01,3.,sf3);
    
    uv -= vec2(-0.8,0.0);
    float sf4 = value(uv*scale, width*scale,tf,1.,-1.,1.,1.,1.,1.);
    col.rgb += 3.*smoothstep(.01,4.,sf4);
    
    col.bg += sf1;
    col.b += sf2;
    col.rg += sf3;
    col.g += sf4;
 
    col = sqrt(col);
    
    glFragColor = vec4(col, 1.);
}

float function( float r, float t, float y, float z, float n1, float a, float b, float n2, float n3) {        
    float ca = cos(y*t/4.);
    float sa = sin(z*t/4.);
    float lf = pow(abs(ca/a),n2);
    float rg = pow(abs(sa/b),n3);
    
    return pow(lf+rg,-1./n1)-r;
}

float solve(vec2 p,float y, float z, float n1, float a, float b, float n2, float n3) {

    float r = length(p);
    float t = atan(p.y, p.x);
    
    float v = 1000.;
    for(int i=0; i<32; i++ ) {
        v = min(v, abs(function(r,t, y,z,n1,a,b,n2,n3)));
        t += PI*2.;
    }
    
    return v;
}

float value(vec2 p, float size, float y, float z, float n1, float a, float b, float n2, float n3) {
    float error = size;
    return 1. / max(solve(p,y,z,n1,a,b,n2,n3) / error, 1.);
}
