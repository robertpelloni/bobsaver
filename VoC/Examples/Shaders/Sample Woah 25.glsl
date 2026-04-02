#version 420

// original https://www.shadertoy.com/view/MltcDn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float box(vec2 st, float size, float s) {
    float c;
    //st = st * 2. - 1.;
    c = length(max(abs(st)-size, 0.));
    c = smoothstep(.01+s, .01, c);
    return c;
}

mat2 rotate2d(float angle) {
    return mat2(cos(angle), -sin(angle),
                   sin(angle), cos(angle));
}

mat2 scale(float amount) {
    return mat2(amount, 0.,
               0., amount);
}

vec2 tile(vec2 st, float count) {
    st *= count;
    
    float oddOrEven = floor(mod(st.y, 2.));
    st.x += count/2.*step(oddOrEven, 0.5);;
    // I want it to be odd / even
    // So I want to look at whether mod mod(2 == 0
    st = fract(st);

    return st;
}

float ring(vec2 st, float r, float w, float s) {
    float f = 0.;

    float l = length(st);
    float inner = smoothstep(r, r+s, l);
    float outer = smoothstep(r+w, r+w+s, l);
    
    f = outer - inner;
    
    return f;
}

void main(void) {
    vec2 st = gl_FragCoord.xy/resolution.y;

    float u_time = time;
    vec3 color = vec3(0.);
   
    st -= vec2(.5);
    st.x -= .4;
    vec2 uv = st;
    
    st*= 2.;
   
    float radius = 0.340 * sin(u_time)/2.+(sin(u_time)/3. + 0.212);
    float width = 0.104 * cos(u_time)/2.+-0.148;
    float softness = -0.228 * cos(u_time)/2.+.6;
    st *= vec2(scale(1.368) * ring(st, radius, width, softness)+sin(u_time/3.)/3.).x;
    
    st *= rotate2d(sin(u_time/10.) + length(st) * .5);

    st *= 5. * sin(u_time/6.) + 10.;
    st = tile(st, 3.);
    
    vec2 boxTransform;
    

    
    
     boxTransform = scale(0.87) * rotate2d(.25 * 3.14) *  (st*2.-1.) ;
    color += box(boxTransform,0.296, 0.042);
    

    
    glFragColor = vec4(color,1.0);
}
