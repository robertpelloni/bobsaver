#version 420

// original https://www.shadertoy.com/view/Ddf3Rr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash(vec2 p){
    p = fract(p*vec2(0.514, 0.12));
    p += dot(p, p+6.135);
    return fract(p.x*p.y);
}

float minkowski_dist(vec2 p, float order){
    p = abs(p);
    return pow(pow(p.x, order)+pow(p.y, order), 1./order);
}

vec4 truchet(vec2 p, vec3 col, float dist_order, float thickness, float pattern){
    vec2 cell_id = floor(p);
    p = fract(p)-.5;

    p.x *= hash(cell_id) > .5 ? 1. : -1.;
    float s = p.x > -p.y ? 1. : -1.;

    vec2 circle_coords = p-vec2(.5)*s;
    float angle = atan(circle_coords.y, circle_coords.x);
    float dist_center = minkowski_dist(circle_coords, dist_order);
    
    float blur = .02;
    float radius = .5;
    float dist_to_edge = abs(dist_center-radius)-thickness;
    float contour = smoothstep(blur, -blur, dist_to_edge);
       
    float d = cos(angle*2.)*0.5+0.5;
    col *= mix(0.4,1., d);
    
    float check = mod(cell_id.x+cell_id.y, 2.)*2.-1.;
    col *= 1.+pattern*sin(check*angle*20.+dist_to_edge*40.-time*10.);
    return vec4(col, d)*contour;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy-resolution.xy*.5)/resolution.y;
    uv += time/(resolution.y*0.1);
    uv *= resolution.y/80.;
    vec3 col = vec3(0);

    vec4 t1 = truchet(uv, vec3(0, 1, 0), 1., 0.14, 0.);
    vec4 t2 = truchet(uv+vec2(.5, .5), vec3(0, 0, 1), 2.0+sin(mod(time, 5.)*5.)/2.+.5, 0.1, 0.3);
    col += t1.a > t2.a ? t1.rgb : vec3(0.);
    col += t2.a > t1.a ? t2.rgb : vec3(0.);

    glFragColor = vec4(col,1.0);
}
