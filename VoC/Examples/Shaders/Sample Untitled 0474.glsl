#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float snow(vec2 uv,float scale)
{
    float _time = time*0.5;
    float w=smoothstep(1.,0.,-uv.y*(scale/10.));if(w<.1)return 0.;
    
    
    uv+=_time/scale;uv.y+=_time*2./scale;uv.x+=sin(uv.y+_time*.5)/scale;
    uv*=scale;vec2 s=floor(uv),f=fract(uv),p;float k=3.,d;
    p=.5+.35*sin(11.*fract(sin((s+p+scale)*mat2(7,3,6,5))*5.))-f;d=length(p);k=min(d,k);
    k=smoothstep(0.,k,sin(f.x+f.y)*0.01);
        return k*w;
}
vec2 onRep(vec2 p, float interval) {
    return mod(p, interval) - interval * 0.5;
}

float barDist(vec2 p, float interval, float width) {
    return length(max(abs(onRep(p, interval)) - width, 0.0));
}

float tubeDist(vec2 p, float interval, float width) {
    return length(onRep(p, interval)) - width;
}

vec3 rotate(vec3 p, float angle, vec3 axis){
    vec3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    mat3 m = mat3(
        a.x * a.x * r + c,
        a.y * a.x * r + a.z * s,
        a.z * a.x * r - a.y * s,
        a.x * a.y * r - a.z * s,
        a.y * a.y * r + c,
        a.z * a.y * r + a.x * s,
        a.x * a.z * r + a.y * s,
        a.y * a.z * r - a.x * s,
        a.z * a.z * r + c
    );
    return m * p;
}

float sceneDist(vec3 p) {
    
 p =     rotate(p, radians(p.z * 12.), vec3(0.0, 0.0, 1.0));

    float bar_x = barDist(p.yz, 1., 0.1);
    float bar_y = barDist(p.xz, 1., 0.1);
    float bar_z = barDist(p.xy, 1., 0.1);

    float tube_x = tubeDist(p.yz, 0.1, 0.025);
    float tube_y = tubeDist(p.xz, 0.1, 0.025);
    float tube_z = tubeDist(p.xy, 0.1, 0.025);

    return max(max(max(min(min(bar_x, bar_y),bar_z), -tube_x), -tube_y), -tube_z);
}

void main( void ) {
    vec2 p = ( gl_FragCoord.xy * 2. - resolution.xy ) / min(resolution.x, resolution.y);
    vec2 uv = p;

    p.x+=sin(time+(p.x*p.y))*0.2;
    p.y+=cos(time+(p.x*p.y))*0.5;
    
    vec3 cameraPos = vec3(0., 0., time * 0.5);
    vec3 cameraTarget = vec3(1., 0.5, time * 0.5);

    float screenZ = 4.5;
    vec3 rayDirection = rotate(normalize(vec3(p, screenZ)), radians(time * 10.), vec3(0.0, 0.0, 1.));

    float depth = 0.0;
    vec3 col = vec3(0.0);

    for (int i = 0; i < 99; i++) {
        vec3 rayPos = cameraPos + rayDirection * depth;
        float dist = sceneDist(rayPos);

        if (dist < 0.0001) {
            col = vec3(.6, .25, 1.) * (1.0 - float(i) / 100.0);
            break;
        }

        depth += dist;
    }
    uv.x += sin(uv.y)*.6;
    uv.y += 2.0;
    uv.y = dot(uv*0.125,uv*0.125);
    float c=snow(uv,30.)*.3;
    c+=snow(uv,20.)*.5;
    c+=snow(uv,15.)*.8;
    c+=snow(uv,10.);
    c+=snow(uv,8.);
    c+=snow(uv,6.);
    c+=snow(uv,5.);
    
    
    glFragColor = vec4(col*0.75+c, 1.);
}
