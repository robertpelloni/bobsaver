#version 420

#define PI 3.14159265359

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sdTriangleIsosceles( in vec2 p, in vec2 q )
{
    p.x = abs(p.x);
    vec2 a = p - q*clamp( dot(p,q)/dot(q,q), 0.0, 1.0 );
    vec2 b = p - q*vec2( clamp( p.x/q.x, 0.0, 1.0 ), 1.0 );
    float s = -sign( q.y );
    vec2 d = min( vec2( dot(a,a), s*(p.x*q.y-p.y*q.x) ),
                  vec2( dot(b,b), s*(p.y-q.y)  ));
    return -sqrt(d.x)*sign(d.y);
}

mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

void main( void ) {

    vec2 uv = ( gl_FragCoord.xy / resolution.xy );
    uv-=.5;
    float ratio = resolution.x/resolution.y;
    uv.x *= ratio;
    
    vec2 uv2=floor((uv+vec2(time*.15,0.0))*10.0)/10.0-vec2(time*.15,0); // uv to pixel 
    float b= pow(1.0-length(mod(uv2+vec2(0.0,.5),0.75)-.375),3.0);
    
    uv = mod(uv+vec2(time*.15,0),.1)*10.; // uv to grid
    uv = rotate2d( b*2.0*PI ) * (uv-.5);
    
    float a = sdTriangleIsosceles(uv,vec2(.1,.3));
    a = step(a,.01);
    
    vec4 o;
    o = vec4(a*b*1.5,a*.5-(b*.5),(a-(b*.33))*(uv2.x*.5+.5),1.0);

    glFragColor = o;

}
