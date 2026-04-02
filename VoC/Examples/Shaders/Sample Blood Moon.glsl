#version 420

// original https://www.shadertoy.com/view/3tdSW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand21(vec2 uv){
     uv = fract(uv*vec2(267.665, 393.725));
     uv += dot(uv, uv + 93.89872);
     return fract(uv.x*uv.y);
}

float smoothrand2(vec2 uv, float size){
    vec2 lv = smoothstep(0.,1., fract(uv*size));
    vec2 id = floor(uv*size);
    
    float bl = rand21(id + vec2(0.,0.));
    float br = rand21(id + vec2(1.,0.));
    float tl = rand21(id + vec2(0.,1.));
    float tr = rand21(id + vec2(1.,1.));
    float b = mix(bl, br, lv.x);
    float t = mix(tl, tr, lv.x);
    float c = mix(b, t, lv.y);
    
    return c;
}

float smootherrand2(vec2 uv, float size){
    float total = smoothrand2(uv, size);
    total += smoothrand2(uv, size*2.)/4.;
    total += smoothrand2(uv, size*4.)/8.;
    total += smoothrand2(uv, size*8.)/16.;
    total += smoothrand2(uv, size*16.)/32.;
     return total;
}

float cloud2(vec2 uv){
    vec2 uv2 = uv;
    uv2.x+=time*.03;
    uv2.x = mod(uv2.x+10.,300.);
    float color = smootherrand2(uv2, 10.)*1.5;

    float d = 1.-length(uv)+.3;
    d = pow(d, 10.);
    d = clamp(d, 0.,1.);
    color *= d;
    
    float min = .2;
    float h = clamp((1.+min)-length(uv.y),0.,1.);
    h = pow(h, 10.);
    clamp(h, 0.,1.);
    color *= h;
    
    return color * .9;
}

float star(vec2 uv, vec2 id){
    
    float d = length(uv);
    float rand = rand21(id);
    float o = (.003/d) * rand;
    float r2 = id.x -id.y *id.x;
    o += sin(r2+time)*.015;
    o *= smoothstep(.4,.1,d);
    return o;
}

float skyFullOfStars(vec2 uv){
    uv*= 10.;
    vec2 gv = fract(uv)-.5;
    vec2 id = floor(uv);
    float col = 0.;
    for(int i=-1;i<=1;++i){
        for(int j=-1;j<=1;++j){
            vec2 offset = vec2(i,j);
            float rand = rand21(id+offset);
            col += star(gv-offset - vec2(rand-.5, fract(rand*10.)-.5), id+offset);
        }
    }
    return col;
}

vec3 backSun(vec2 uv){
    vec3 color = vec3(skyFullOfStars(uv));
    float tmp = clamp((1.- length(uv*2.5)), 0., 1.);
    color = clamp(color - tmp , 0., 1.);

    if(length(uv) < .3){
        color = mix(vec3(.94, .29, .26),vec3(.99, .63, .38), 1.-(uv.y+.3)/.6); // color sun original
        //color = mix(vec3(0.5, 0.,0.),vec3(.86, .07, .23), 1.-(uv.y+.3)/.6); // gregoire color
    }

    else{
        float x = 1.3-length(uv);
        x = pow(x, 25.); 
        color += x * vec3(.84,.16,.16);
    }
    return color;
}

void main(void) {
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv-=.5;
    uv.x*= resolution.x/resolution.y;
    vec3 color = backSun(uv);
    float alpha = clamp(cloud2(vec2(uv.x, uv.y+.2)), 0., 1.);
    alpha = clamp(alpha-.01, 0.,1.);
    vec3 cloudColor = mix(vec3(.15,.14,.32), vec3(.94, .29, .56), (uv.y+.3)*3.); // original
    //vec3 cloudColor = vec3(.0,.0,.5);

    color = cloudColor*alpha + (1. - alpha)*color;
    //color = vec3(uv.y+.1)*3.;
    //color = vec3(skyFullOfStars(uv));
    glFragColor = vec4(color,1.0);
}
