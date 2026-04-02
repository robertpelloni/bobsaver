#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {
    
    float ratio = resolution.x/resolution.y;
    float pi = 3.14159265;
    float deg = 45.0;
    float thetaa = pi*deg/180.0;
    float theta = thetaa+time/25.;
    float theta2 = theta+pi*.3333+time/8.;
    float theta3 = theta+pi*.6666+time/5.;
    float t=time/5.0*0.; 

    vec2 p = ( gl_FragCoord.xy / resolution.xy )*vec2(2.0,2.0/ratio) - vec2(1.0,1.0/ratio);
    theta += t;
    
    vec2 pr = vec2(p.x*cos(theta) - p.y*sin(theta), p.y*cos(theta) + p.x*sin(theta));
    vec2 pr2 = vec2(p.x*cos(theta2) - p.y*sin(theta2), p.y*cos(theta2) + p.x*sin(theta2));
    vec2 pr3 = vec2(p.x*cos(theta3) - p.y*sin(theta3), p.y*cos(theta3) + p.x*sin(theta3));
    
    vec3 c1 = vec3(0.0);
    
    c1.r = smoothstep(.7, .95, 1.0-sin(pr.x*50.0)*sin(pr.y*40.0))*1.0;
    c1.g = smoothstep(.7, .95, 1.0-sin(pr2.x*60.0)*sin(pr2.y*100.0))*0.9;
    c1.b = smoothstep(.7, .95, 1.0-sin(pr3.x*80.0)*sin(pr3.y*60.0))*1.0;
    
    glFragColor = vec4( c1.r, c1.g, c1.b, 1.0 );
}
