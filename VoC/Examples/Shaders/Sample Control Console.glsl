#version 420

// original https://www.shadertoy.com/view/tlGBzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Cole Peterson (Plento)

vec2 R;
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))
#define ss(a, b, t) smoothstep(a, b, t)
float hsh21(vec2 p){
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float hsh11(float p){
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

#define cl 2.3
#define fr 3.5

vec3 color(vec2 uv){
    uv*=1.3;
    
    vec3 col = vec3(1);
    float t = .5*time + 12.;
    vec2 tuv = uv;

    uv.x*=.7;
    float m = clamp(exp((sin(uv.y*8. + 1.6)))*2.8 + .1, cl, fr);
    uv.x *= m;
    
    uv.x += t*1.2;
    
    vec2 fuv = fract(uv*4.);
    vec2 id = floor(uv*4.);
    
    uv.y += .7*time*sin(id.x*.55);
    id = floor(uv*4.);
    
    float rnd = hsh11(id.x*999.3);
    col *= mix(1., .02, step(rnd, .3));
    
    float x = id.x*43.2 + id.y*22.5;
    float sp = ss(0.25, 0.2, abs(fuv.x-0.5));
    float chk = mod(id.y+id.x,2.0)*hsh21(id*999.) * sp;
    col *= .5+.45*cos(vec3(.0, .7, .2)*(x + hsh11(floor(time*2. + x)))*10.);
    col *= hsh11(floor(time + x));
    
    col *= sp;
    col *= chk;
    
    if(m >= fr) col *= 1.5;
    else if(m <= cl){
        col = .011 + .04*vec3(chk);
        col += (.5+.7*cos(uv.x*5.))*.025;
    }
    else col *= .5;
    
    return col;
}

void main(void) {
    R = resolution.xy;
    vec2 uv = vec2(gl_FragCoord.xy - 0.5*R.xy)/R.y;
    
    uv.y += uv.x*.1;
    uv.y = -abs(uv.y);
    
    vec3 col = color(uv);
    vec3 acc = vec3(0);
    
    float c = 0.0;
    for(float i = 0.9; i >0.1; i-=0.04){
        vec2 nv = uv*(i+hsh21(gl_FragCoord.xy)*0.15);
        vec3 nc = color(nv);
        acc += nc*nc*nc*2.;
        c++;
    }
    
    acc /= c;
    
    col += acc*.13;
    col *= .6;
    col *= (1.-step(.78, abs(uv.x)));
    col = 1.-exp(-col);
    glFragColor = vec4(sqrt(clamp(col, 0.0, 1.0)), 1.0);
}

