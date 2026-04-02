#version 420

// original https://www.shadertoy.com/view/WsBBRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pixelWidth 2.0/resolution.y
#define N 4
#define A 0.59
#define red vec3(1.0, 0.0, 0.0)
#define white vec3(1.0)

vec3 light = vec3(0.05, 1.0, 0.85);

// sdPoly adapted from https://www.shadertoy.com/view/WdSGRd 
float sdPoly( in vec2[N] v, in vec2 p )
{
    float d = dot(p-v[0],p-v[0]);
    float s = -1.0;
    for( int i=0, j=N-1; i<N; j=i, i++ )
    {
        // distance
        vec2 e = v[j] - v[i];
        vec2 w = p - v[i];
        vec2 b = w - e*clamp( dot(w,e)/dot(e,e), 0.0, 1.0 );
        d = min( d, dot(b,b) );
        
        // winding number from http://geomalgorithms.com/a03-_inclusion.html
        bvec3 cond = bvec3( p.y>=v[i].y, p.y<v[j].y, e.x*w.y>e.y*w.x );
        if( all(cond) || all(not(cond)) ) s*=-1.0;  
    }
    
    return smoothstep(-pixelWidth, pixelWidth, s*sqrt(d));
}

void drawCuboid(inout vec4 c, vec2 p, vec3 color, float width, float height, float depth)
{   
    height = max(pixelWidth, height);
    vec2 v0 = vec2(0, height);
    vec2 v1 = v0 + vec2(depth, A*depth);
    vec2 v2 = v1 - vec2(0, height);
    vec2 v3 = v0 - vec2(0, height);
    
    vec2 v4 = v0 - vec2(width, -A*width);
    vec2 v5 = v4 - vec2(0, height);
    
    vec2 v6 = v4 + vec2(depth, A*depth);
    
    vec2[] polyRight = vec2[](v0,v1,v2,v3);
    vec2[] polyLeft = vec2[](v0,v4,v5,v3);
    vec2[] polyTop = vec2[](v0,v4,v6,v1);
    
    float right = sdPoly(polyRight, p);
    float left = sdPoly(polyLeft, p);
    float top = sdPoly(polyTop, p);
    
    float a = clamp(top + right + left, 0.0, 1.0);
    
    //Crayon-like border
    //vec3 result = step(0.9, top) * vec3(1.0) + step(0.9, right) * vec3(0.85) + step(0.9, left) * vec3(0.05);

    vec4 result = vec4(light.y*color, top);
    result = mix(result, vec4(light.z*color, right), right);
    result = mix(result, vec4(light.x*color, left), left);
    
    c = mix(c, result, pow(a, 4.0));
}

float st(float a, vec2 uv)
{
    return sin(a*time+a*uv.y*uv.x);
}

void main(void)
{
    vec2 U = (2.0*gl_FragCoord.xy-resolution.xy)/(resolution.y);
    vec2 p = fract(U) - vec2(.5, 0.4);
    
    float s = 0.2*.6;
    
    vec4 col = vec4(0);
    
    //Lighting change
    light.x = 0.5 + 0.35*pow(sin(time), 3.);
    light.z = 0.5 + 0.35*pow(sin(time + 3.), 3.);
    
    // Draw red cuboid
    drawCuboid(col, p, red, s*(1.0+0.5*st(3.5, U)), s*(1.0+st(5., U)), s*(1.0+0.25*st(2., U)));
    // Draw blue-ish one
    U *= 1.1;
    drawCuboid(col, p-vec2(0.1,-0.2), vec3(0.6, 0.8, 1.0), s*(1.0+0.5*st(3.5, U)), s*(1.0+st(5., U)), s*(1.0+0.25*st(2., U)));    

    
    glFragColor = vec4(col);
}
