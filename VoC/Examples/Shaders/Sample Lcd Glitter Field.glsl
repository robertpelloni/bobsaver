#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 hash( vec2 p )
{
    p = vec2( dot(p,vec2(127.1,311.7)),
              dot(p,vec2(269.5,183.3)) );

    return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main(void)
{
    vec2 q = gl_FragCoord.xy / resolution.xy;
    vec2 p = -1.0+2.0*q;
    p.x *= resolution.x/resolution.y;
    float speed = .2;
    vec3 ro = .7*vec3(cos(time*speed), 1.0, sin(time*speed));
        vec3 ta = vec3(0);

    // camera-to-world transformation
    mat3 ca = setCamera(ro, ta, 0.0);

    // ray direction
    vec3 rd = ca*normalize(vec3(p.xy,2.0));

        float n = sin(time*0.6)*10.+50.;
    vec3 column = normalize(floor(rd*n));
    vec2 polar = vec2(acos(column.z), atan(column.y/column.x));
        vec2 h = hash(polar);
    float dist = length(h);
    vec3 col = dist*(vec3(1.)-vec3(step(0.5, length(fract(rd*n)-vec3(0.5))/clamp(dist, 0.0, 1.))));
        col = col*vec3(h.x, h.y, 0.5);
    glFragColor = vec4(col.x, col.y, col.z, 1.);
}
