#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D buf;

out vec4 glFragColor;

void main( void ) {

    vec2 uv = ( gl_FragCoord.xy / resolution.xy );
    vec2 p = (uv*2.-1.) * vec2(resolution.x/resolution.y,1.);

    float lit = 999.;
    for(int i = 0; i<10; i++) {
        float t = time + float(i)*.1;
        vec2 v = cos(t*.1*float(i))*vec2( cos(t*1.5), sin(t*3.) ) + sin(t*.1*float(i)) * vec2( cos(t*2.), sin(t*.75) );
        lit = min(lit, length(p-v));
    }

    glFragColor = vec4( .01/lit ) + vec4(.95, .9, .85,1.) * texture2D( buf, uv );

}
