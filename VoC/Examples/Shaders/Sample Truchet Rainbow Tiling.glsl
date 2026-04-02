#version 420

// original https://www.shadertoy.com/view/3dd3R2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash(vec2 p)
{
    return fract(sin(dot(p, vec2(27.754, 78.4476))) * 47125.3567);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y * 10.;
    uv.x += sin(time*3. + uv.y*0.3)*0.5;
    vec2 fluv = floor(uv);
    vec2 fruv = fract(uv) - 0.5;
    float t = fruv.y - fruv.x;
    if (hash(fluv) > 0.5) {t = fruv.y + fruv.x;}
    vec3 col = smoothstep(0.1,0.0,vec3(abs(t))) + smoothstep(0.9,1.0,vec3(abs(t)));
    col *= sin(abs(uv.y*0.1 + (time*3.)))*0.5+0.5;
    col *= 0.5 + 0.5*cos(time*5.+uv.yyy*0.2+vec3(0,2,4));
    glFragColor = vec4(col,1.0);
}
