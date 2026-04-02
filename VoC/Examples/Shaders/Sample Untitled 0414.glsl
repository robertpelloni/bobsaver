#version 420

uniform float time;

out vec4 glFragColor;

void main()
{
    vec2 p = 2.0*gl_FragCoord.xy/164.0;
    for (int n=1; n<10; n++) {
        float i = float(n);
        p += (vec2(
            // whole lotta garbage
            0.7/i*sin(i*p.x+time+0.3*i)+cos(p.y/99.0),
            0.4/i*sin(i*p.x+time+0.3*i)+4.6
            )*3.0)/2.0+sin((p.x-time)/34.);
    }
    p.xy += sin(time*343.0)/19.; // flicker
    glFragColor = vec4(0.5*sin(p.x)+0.5,0.5*sin(p.x),0.05,1.0);
}
