#version 420

// original https://www.shadertoy.com/view/MlcXRl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// z * z
vec2 zmul(vec2 a, vec2 b)
{
    //return vec2(a.x*b.x-a.y*b.y, a.x*b.y+b.x*a.y);
    return mat2(a,-a.y,a.x)*b;
}

// 1 / z
vec2 zinv(vec2 a)
{
    return vec2(a.x, -a.y) / dot(a,a);
}

void main(void)
{
    vec2 g = gl_FragCoord.xy;
    
    vec2 si = resolution.xy;
    
    vec2 uv = (g+g-si)/min(si.x,si.y) ;
    
    uv *= 30. * (sin(10.6+time * 0.01)*.5+.5);//zoom
    
    uv += vec2(-0.46022,0.746155);
    
    //if (mouse*resolution.xy.z > 0.)
    //    uv = (g+g-si)/min(si.x,si.y) * 2.;
    
    vec2 z = uv;
    
    vec2 c = vec2(0.66,1.23);
    
    float it = 0.;
    for (int i=0;i<600;i++)
    {
        z = zinv(zmul(z, z) + c);
        if( dot(z,z)>4. ) break;
        it++;
    }
    
    float sit = it-it/(log2(log2(dot(z,z))));
    
    glFragColor = 0.5 + 0.5 * cos( 3. + sit*0.2 + vec4(0,0.6,1,1));
}
