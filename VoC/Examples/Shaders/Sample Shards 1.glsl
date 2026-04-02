#version 420

// original https://www.shadertoy.com/view/7dd3zn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float pi = acos(-1.);

//https://gist.github.com/companje/29408948f1e8be54dd5733a74ca49bb9
float map_range(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

//https://gist.github.com/ayamflow/c06bc0c8a64f985dd431bd0ac5b557cd
vec2 rotateUV(vec2 uv, float rotation)
{
    float mid = 0.5;
    return vec2(
        cos(rotation) * (uv.x - mid) + sin(rotation) * (uv.y - mid) + mid,
        cos(rotation) * (uv.y - mid) - sin(rotation) * (uv.x - mid) + mid
    );
}

//https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float map(vec2 uv) {
    int iterations = 5;
    vec2 ouv = uv;
    
    uv.y += time/32.;
    uv = abs(mod(uv, 1.)*4. - 2.);
    
    for(int i = 0; i < iterations; i ++) {
        float fi = float(i);
        float fit = float(iterations);
        uv = abs(uv - (vec2(cos(time/4.) + (fi/fit))));
        uv *= 1.1;
        uv = rotateUV(uv, map_range(ouv.x,-1.,1., 0.5, 5.) );
    }
    
    return sdBox(uv, vec2(0.2));
}

//https://www.shadertoy.com/view/MsGSRd
vec2 getGrad(vec2 uv,float delta)
{
    vec2 d=vec2(delta,0);
    return vec2(
        map(uv+d.xy)-map(uv-d.xy),
        map(uv+d.yx)-map(uv-d.yx)
    )/delta;
}

// https://www.shadertoy.com/view/wlSBzD
vec3 SpectrumPoly(in float x) {
    return (vec3( 1.220023e0,-1.933277e0, 1.623776e0)+(vec3(-2.965000e1, 6.806567e1,-3.606269e1)+(vec3( 5.451365e2,-7.921759e2, 6.966892e2)+(vec3(-4.121053e3, 4.432167e3,-4.463157e3)+(vec3( 1.501655e4,-1.264621e4, 1.375260e4)+(vec3(-2.904744e4, 1.969591e4,-2.330431e4)+(vec3( 3.068214e4,-1.698411e4, 2.229810e4)+(vec3(-1.675434e4, 7.594470e3,-1.131826e4)+ vec3( 3.707437e3,-1.366175e3, 2.372779e3)*x)*x)*x)*x)*x)*x)*x)*x)*x;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 uv_o = uv;    
    uv /= dot(uv,uv);
    
    //Log polar-tiling -> https://www.osar.fr/notes/logspherical/
    vec2 pos = vec2(log(length(uv)), atan(uv.y, uv.x));
    pos *= 1./pi;
    pos = fract(pos) - 0.5;   
    uv = pos;
    uv.x += time/2. + 5700.;

    //Lightning
    vec2 norm = normalize(getGrad(uv, 0.011));
    float l_speed = 2.5;
    vec2 lightpos = vec2(sin(time*l_speed), cos(time*l_speed));
    float light = abs(dot(norm, normalize(lightpos)));
    vec3 color = SpectrumPoly(sin(light*2. + sin((time + 14.)/3.))*0.5 + 0.5)*1.4;
    
    //Shine
    float mask = (1. - pow(length(uv_o),0.2))*map_range(sin(time), -1.,1., 1.8, 2.);
    color += vec3(mask,mask,mask*0.82);
    glFragColor = vec4(color,1.0);
}
