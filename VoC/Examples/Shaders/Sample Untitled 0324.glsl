#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 red = vec3(1.0, 1.0, 1.0);
vec3 blue = vec3(0.0, 0.0, 0.0);

vec3 space2Col( vec3 pos)
{
    float r = sin(pos.x)*0.5+0.5;
    float g = sin(pos.y)*0.5+0.5;
    float b = sin(pos.z)*0.5+0.5;
    return vec3(r,g,b);
}

void main( void ) {

    vec2 position = ( gl_FragCoord.xy / resolution.xy );

    vec3 color = vec3(0.0);
    //color += sin( position.x * cos( time / 15.0 ) * 80.0 ) + cos( position.y * cos( time / 15.0 ) * 10.0 );
    //color += sin( position.y * sin( time / 10.0 ) * 40.0 ) + cos( position.x * sin( time / 25.0 ) * 40.0 );
    //color += sin( position.x * sin( time / 5.0 ) * 10.0 ) + sin( position.y * sin( time / 35.0 ) * 80.0 );
    //color *= sin( time / 10.0 ) * 0.5;
    if (sin((((position.x)-0.5)*(1.0/abs(position.y-0.5))+(time/5.0) )*10.0) > 0.0) { color = red; } else { color = blue; }
    if (sin((abs(position.y*10.0))*(1.0/abs(position.y-0.5))) > 0.0) { color = blue; }
    color *= abs(position.y-0.5)*2.0;
    color *= space2Col(vec3(time,position));
    glFragColor = vec4( color, 1.0 );

}
