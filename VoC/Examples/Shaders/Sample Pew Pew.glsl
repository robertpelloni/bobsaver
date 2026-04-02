#version 420

// original https://www.shadertoy.com/view/4c2fzG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float linedist(vec2 a, vec2 b, vec2 p)
{
    return length(clamp(dot(p-a, b-a)/dot(b-a,b-a), 0., 1.) * (b-a) + a - p);
}

vec3 FIRE(vec2 uv)
{

    vec2 a = vec2(-3, 0.);
    vec2 b = vec2( 1, 0.);
    
    float dist = linedist(a, b, uv);

    float alpha = smoothstep(0.1, 0., dist-0.01) * smoothstep(a.x, 1., uv.x) * smoothstep(1.1, .9, uv.x+pow(3.*abs(uv.y), 2.));
    float glow = 2. / (2. + 100.*dist);

    float fire_intensity = glow * (1.-alpha)* smoothstep(a.x, 1., uv.x) + alpha;

    //float T = clamp(fire_intensity, 0., 1.);
    float T =  sqrt(tanh(fire_intensity * fire_intensity)); // soft clamp

    #if 1
    // Add some variation
    // This is low quality :)
    T += 0.001+ 0.001*sin(12. * smoothstep(-1., 1., uv.x) + time*3.) * 
        (0.01 + 0.001*sin(54. * smoothstep(-0.11, .5, uv.y) + time*3.) * smoothstep(1., -1., uv.x));
    #endif

    // fire gradient:
    // White, yellow, orange, red, black
    // vec3(1), vec3(1,1,0), vec3(1, 0, 0), vec3(0,0,0)
    // Observation: red decays slowest, green moderately slow, and blue decays fast, as temperature drops.
    vec3 fire = 
    3.*vec3(
        pow(T, 1.1),
        pow(T, 2.5),
        pow(T, 5.)
    );

    return fire;
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;

    const float PI = 3.14159265;
    vec2 uv1 = vec2(log(length(uv))/.75, (atan(uv.y, uv.x))/(PI/2.));
    
    vec2 uv2 = vec2(log(length(uv))/.75, (atan(uv.y, -uv.x))/(PI/2.));

    vec3 color = vec3(0);
    float speed = 30.;
    
    float mask1 = smoothstep(-2., 2.*-.5, uv1.y) * smoothstep(2., 2.*.5, uv1.y);
    float mask2 = smoothstep(-2., 2.*-.5, uv2.y) * smoothstep(2., 2.*.5, uv2.y);
    
    // Animate:
    float instance = floor(speed * time/15.);
    float cycle = fract(speed * time/15.);
    
    float instance2 = floor(speed * (111.5+time)/15. + .5);
    float cycle2 = fract(speed * (time+111.5)/15. + .5);
    
    uv1.x += 5.-cycle*10.;
    uv1.y += -1. + 2. * fract(cos(instance * 2.39996322972865)*3238.72345);
    
    
    uv2.x += 5.-cycle2*10.;
    uv2.y += -1. + 2. * fract(cos(instance2 * 2.39996322972865)*4231.72345);
    
    
    #if 1
    // Add some distortion
    // This is low quality :)
    uv1 += 0.001*sin(50. * smoothstep(-1., 1., uv1.x) + time*30.);
    uv1 += 0.01*sin(64. * smoothstep(-0.1, .5, uv1.y) + time*30.) * smoothstep(1., -1., uv1.x);
    uv2 += 0.001*sin(50. * smoothstep(-1., 1., uv2.x) + time*30.);
    uv2 += 0.01*sin(64. * smoothstep(-0.1, .5, uv2.y) + time*30.) * smoothstep(1., -1., uv2.x);
    #endif 
    
    color += FIRE(uv1) * mask1;
    color += FIRE(uv2) * mask2;
    
    color = sqrt(tanh(color*color));
    pow(color, vec3(1./2.2));
    glFragColor = vec4(color,1.0);
}
