#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void){
    vec2 p = gl_FragCoord.xy / resolution.xy;
    vec4 dmin = vec4(1000.);
    vec2 z = (-1.0 + 2.0*p)*vec2(1.7,1.0);
    for( int i=0; i<64; i++ ){
        z = (mouse.xy-vec2(0.5))*1.6+vec2(z.x*z.x-z.y*z.y,2.0*z.x*z.y);
        dmin=min(dmin,vec4(abs(0.0+z.y+0.5*sin(z.x)),abs(1.0+z.x+0.5*sin(z.y)),dot(z,z),length(fract(z)-0.5)));}    
    vec3 color = vec3( mix(vec3(dot(dmin.rgb, -dmin.gba)), dmin.rgb, 1.0-dmin.a) );
    color = mix( color, vec3(0.00,1.00,1.00),  1.00-min(1.0,pow(dmin.x*0.25,0.20)));
    color = mix( color, vec3(1.00,0.00,1.00),  1.00-min(1.0,pow(dmin.y*0.50,0.50)));
    color = mix( color, vec3(1.00,1.00,0.00),  1.00-min(1.0,pow(dmin.z*1.00,0.15)));
    color = 1.25*color*color;
    glFragColor = vec4(1.0-color*(0.5 + 0.5*pow(16.0*p.x*(1.0-p.x)*p.y*(1.0-p.y),0.15)),1.0);
}
