#version 420

// original https://www.shadertoy.com/view/WdcBDj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float circleD(vec2 center, float radius)
{
    return length(center) - radius;
}

vec4 circumference(vec2 center, float radius, float lw, vec3 color) {
    float d = circleD(center, radius);
    float a = smoothstep(1.0, 0.0, abs(d)/lw);
    return vec4(color.rgb,a);    
}

vec4 waveThing(vec2 uv, float lw, vec3 color) {
    float a = smoothstep(1.0,0.0,abs(cos((uv.x)*4.0)/4.0 - uv.y)/lw);
    return vec4(color.rgb, a);
}

vec4 waveThing2(vec2 uv, float lw, vec3 color) {
    float a = smoothstep(1.0,0.0,abs(cos((uv.x)*2.0)/2.0 - uv.y)/lw);
    return vec4(color.rgb, a);
}

vec4 waveThing3(vec2 uv, float lw, vec3 color) {
    float a = smoothstep(1.0,0.0,abs(cos((uv.x)*20.0)/20.0 - uv.y)/lw);
    return vec4(color.rgb, a);
}

void main(void)
{
    const float radius = 0.5;
    
    float linew = 0.009;//resolution.y * 0.00003;
    float x = time;

    float aspect = resolution.x / resolution.y;
    
    vec2 uv = (gl_FragCoord.xy / resolution.xy) * 2.0 - 1.0;
    uv.x *= aspect;
    
    vec2 center = uv;
    
    // initierar musrörelse kopplat till canvasen
     vec2 move = mouse*resolution.xy.xy / resolution.y;
    
    //Bakgrunden sätts
    vec4 acc = vec4(0,0,0,0);
    vec4 c = circumference(center, radius, linew, vec3(0,1,0));
    //acc = mix(acc, c, c.a);
    
    //Vågen ritas ut
    c = waveThing(uv + vec2(0, 0.25), linew, vec3(1,0.5,.5));
    acc = mix(acc, c, c.a);
    
    //Här ritas lilla cirkeln ut, orginal
    float xx = sin (x*0.2) * aspect;
    center = vec2(xx, cos((xx)*4.0)/4.0) - (uv + vec2(0, 0.25));
    c = circumference(center, 0.05, linew, vec3(1,0,1));
    acc = mix(acc, c, c.a);
    
    //test att påverka lilla cirkeln med musrörelser istället
    // Här sätts xx till att styras av musrörelser
    //float xx = sin (move.y) * aspect;
    // Här styr jag hastigheten med musen
    //center = vec2(xx, cos((xx)*4.0)/4.0) - (uv + vec2(0, 0.25));
    //xx = 2. - move.x * 2.1;
    //c = circumference(center, 0.05, linew, vec3(1,0,1));
    //c /= move.x *2.;
    //acc = mix(acc, c, c.a);
    
    //En till våg ritas ut
    c = waveThing2(uv + vec2(0., 0.01), linew, vec3(0,0,1));
    acc = mix(acc, c, c.a);
    
    //Här ritas en till cirkel ut
    xx = sin (x*0.15) * aspect;
    center = vec2(xx, cos((xx)*2.0)/2.0) - (uv + vec2(0, 0.01));
    c = circumference(center, 0.15, linew, vec3(1,1,1));
    acc = mix(acc, c, c.a);
    
    //En till våg ritas ut
    c = waveThing3(uv-0.3 + vec2(0., 0.01), linew, vec3(0,1,1));
    acc = mix(acc, c, c.a);
    
    //Här ritas en tredje cirkel ut
    xx = -0.3 + sin (x*0.4) * aspect;
    center = vec2(xx, cos((xx)*20.0)/20.0) - (uv -0.3 + vec2(0., 0.01));
    c = circumference(center, 0.018, linew, vec3(1,1,0));
    acc = mix(acc, c, c.a);
    
    //Här ritas en fjärde cirkel ut
    xx = -0.3 + sin (x*0.3) * aspect;
    center = vec2(xx, cos((xx)*20.0)/20.0) - (uv -0.3 + vec2(0., 0.01));
    c = circumference(center, 0.028, linew, vec3(1,0,0));
    //c += uv.x/5. + uv.y/5. * sin(time);
    acc = mix(acc, c, c.a);
    

    
    glFragColor = acc;
}
