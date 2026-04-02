#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash(in float n){ return fract(sin(n)*43758.5453); }
mat2 mm2(in float a){float c = cos(a), s = sin(a);return mat2(c,-s,s,c);}

float tri(in float x){return abs(fract(x)-.5);}

vec3 tri3(in vec3 p){
    return vec3( tri(p.z+tri(p.y*1.)), tri(p.z+tri(p.x*1.)), tri(p.y+tri(p.x*1.)));
}                           
mat2 m2 = mat2( 0.970,  0.242, -0.242,  0.970 );

 

float triNoise3d(in vec3 p)
{
    float z=1.5;
    float rz = 0.;
    vec3 bp = p;
    for (float i=0.; i<=3.; i++ )
    {
        vec3 dg = tri3(bp*2.)*1.;
        p += (dg+time*0.25);

        bp *= 1.8;
        z *= 1.5;
        p *= 1.1;
        p.xz*= m2;
        
        rz+= (tri(p.z+tri(p.x+tri(p.y))))/z;
        bp += 0.14;
    }
    return rz;
}

vec2 tri2(in vec2 p)
{
    const float m = 1.5;
    return vec2(tri(p.x+tri(p.y*m)),tri(p.y+tri(p.x*m)));
}

void main( void ) {
    
    float l=0.01*abs(sin(time/4.0));
    
    

    vec2 position = ( gl_FragCoord.xy / resolution.xy )*2.0-1.0;
    position.x*=resolution.x/resolution.y;
    
    float dis=distance(vec2(0.0), l/tri2(position));
    
    float x=0.1/dis;
    
    x+=4.0*triNoise3d(vec3(position,0.));
    
    float m=1.0/distance(position, vec2(0.0));
    
    

    glFragColor = vec4(0.3*m/(x*x),0.03,1.0/x,1.0); 

}
