#version 420

//http://jp.wgld.org/js4kintro/editor/#precision%20mediump%20float%3B%0Auniform%20float%20t%3B%20%2F%2F%20time%0Auniform%20vec2%20%20r%3B%20%2F%2F%20resolution%0A%0Afloat%20get(%20vec2%20p%20)%0A%7B%0A%09float%20c%20%3D%200.0%3B%0A%09for(int%20i%3D0%3Bi%3C10%3Bi%2B%2B)%0A%09%7B%0A%09%09float%20o%20%3D%20t%2Bfloat(i)*100.0%3B%0A%09%09vec2%20q%20%3D%20vec2(%20sin(o*0.23)%2C%20cos(o*0.31)%20)%3B%0A%09%09c%20%2B%3D%20exp(length(q-p)*-3.0)%3B%0A%09%7D%0A%09float%20r%20%3D%20clamp(log(c)%20*%2010.0%2C%200.0%2C%201.57)%3B%0A%09return%20sin(r)%3B%0A%7D%0A%0Avoid%20main(void)%0A%7B%0A%09vec2%20p%20%3D%20(gl_FragCoord.xy%20*%202.0%20-%20r)%20%2F%20min(r.x%2C%20r.y)%3B%0A%09float%20g%20%3D%20get(p)%3B%0A%09vec3%20n%20%3D%20normalize(vec3(%20g%20-%20get(p%2Bvec2(0.01%2C%200.0))%2C%20g%20-%20get(p%2Bvec2(0.0%2C%200.01))%2C%200.3%20))%3B%0A%09p%20%2B%3D%20n.xy%20*%20-0.2%3B%0A%09float%20c%20%3D%20mod(floor(p.x%20*%2012.0)%20%2B%20floor(p.y%20*%2012.0%20-%20t*0.5)%2C%201.5)%20%2B%201.0%3B%0A%09c%20*%3D%20n.z%20*%200.24%3B%0A%09c%20%2B%3D%20pow(abs(dot(n%2C%20vec3(0.7)))%2C%2080.0)%3B%0A%09vec3%20col%20%3D%20vec3(1.0-g*0.4%2C%201.2-g*0.6%2C%201.7)%3B%0A%09glFragColor%20%3D%20vec4(col*pow(c%2C%201.0%2F2.2)%2C%201.0)%3B%0A%7D%0A

precision mediump float;
uniform float time; // time
uniform vec2  resolution; // resolution

out vec4 glFragColor;

float get( vec2 p )
{
    float c = 0.0;
    for(int i=0;i<10;i++)
    {
        float o = time+float(i)*100.0;
        vec2 q = vec2( sin(o*0.23), cos(o*0.31) );
        c += exp(length(q-p)*-3.0);
    }
    float r = clamp(log(c) * 10.0, 0.0, 1.57);
    return sin(r);
}

void main(void)
{
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
    float g = get(p);
    vec3 n = normalize(vec3( g - get(p+vec2(0.01, 0.0)), g - get(p+vec2(0.0, 0.01)), 0.3 ));
    p += n.xy * -0.2;
    float c = mod(floor(p.x * 12.0) + floor(p.y * 12.0 - time*0.5), 1.5) + 1.0;
    c *= n.z * 0.24;
    c += pow(abs(dot(n, vec3(0.7))), 80.0);
    vec3 col = vec3(1.0-g*0.4, 1.2-g*0.6, 1.7);
    glFragColor = vec4(col*pow(c, 1.0/2.2), 1.0);
}
