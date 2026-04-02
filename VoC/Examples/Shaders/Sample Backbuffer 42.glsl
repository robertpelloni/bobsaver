#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D bb;

out vec4 glFragColor;

vec2 mirroredrepeat(vec2 p){ 
    vec2 f = floor(p);
    if(mod(f.x, 2.0) < 0.01) p.x = p.x - f.x;
    else 1.0 - (p.x - f.x);
    if(mod(f.y, 2.0) < 0.01) p.y = p.y - f.y;
    else 1.0 - (p.y - f.y);
    return p;    
} 
vec4 textureSurround(vec2 q, vec3 e, bool odd){
    
    float p10 = 0.0;
    float p01 = 0.0;
    float p21 = 0.0;
    float p12 = 0.0;

    return vec4(p10, p01, p21, p12);
}

void main( void ) {

    vec2 q = ( gl_FragCoord.xy / resolution.xy );
    vec3 e = vec3(vec2(1.0)/resolution.xy,0.);
    q.y -= e.y * 2.0;
    vec4 c = texture2D(bb, q);
    float p11 = c.a > 0.5 ? c.x : c.y;
    vec4 pp = vec4(0.0);        
    if(c.a > 0.5){
        pp.x = texture2D(bb, mirroredrepeat(q-e.zy)).y;
        pp.y = texture2D(bb, mirroredrepeat(q-e.xz)).y;
        pp.z = texture2D(bb, mirroredrepeat(q+e.xz)).y;
        pp.w = texture2D(bb, mirroredrepeat(q+e.zy)).y;
    
    } else {
        
        pp.x = texture2D(bb, mirroredrepeat(q-e.zy)).x;
        pp.y = texture2D(bb, mirroredrepeat(q-e.xz)).x;
        pp.z = texture2D(bb, mirroredrepeat(q+e.xz)).x;
        pp.w = texture2D(bb, mirroredrepeat(q+e.zy)).x;
    } 
    
    float d =  0.0; 
    d += -p11 + (pp.x + pp.y + pp.z + pp.w)*0.5000;
    d += p11 * 0.0004;
    d += smoothstep(0.997,0.998,1.0 - length(mouse.xy + vec2(sin(time * 10.0) * sin(time * 8.0) * sin(time * 7.0)  * 0.5 + 0.5) * 0.04 - q.xy)); 
    //d *= 1.0 - smoothstep(0.98, 1.0, d);
    if(c.a > 0.5){
        glFragColor = vec4( d, c.y, d, 1.0 - c.a );
    } else {
        glFragColor = vec4( c.x, d, d, 1.0 - c.a );
    }

}
