#version 420

// original https://www.shadertoy.com/view/WlBGDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//boing
float map(vec3 p, float height, float k) {
    vec3 pc = vec3(normalize(p.xy)*0.2, clamp(p.z, 0.0,height/k));
    float d2 = asin(sin((p.z*k+0.5*atan(pc.x,pc.y)-time*acos(-1.)*2.0)))/k;
    
    return length(vec2(distance(p, pc), d2))-0.08;
}

float map2(vec3 p, inout vec3 q, inout float angl) {
    q=p;
    angl = 0.5;
    float h = 15.0;
    float c = 8. + cos(time*acos(-1.)*0.5)*0.5;
    float dist = map(p, h, c);
    vec3 pc = p;
    float X = 0.6 + sin(time*acos(-1.)*0.5)*0.1;
    float mul = 1.0;
    for (int i = 0; i < 10; i++) {
        pc -= vec3(0.0,0.0,(h+0.5)/c*mul);
        float stor = sign(pc.y);
           pc = vec3(pc.x, abs(pc.y)-0.1, pc.z);
        mat3 rot = mat3(1.0, 0.0, 0.0,
                    0.0, cos(X), sin(X),
                    0.0,-sin(X), cos(X));
        pc=rot*pc;
        pc=(rot*rot*pc.zyx).zyx;
        h*=0.93;
        X*=0.95;
        mul*=0.84;
        c*=1.03;
        float dist2 = map(pc/mul, h, c)*mul;
        if (dist2 < dist) {
            float piss = pc.z/(h/c);
            angl += stor * pow(2.0, -float(i+1))*piss;
            dist = dist2;
            q=pc/mul;
        }
    }
    
    return dist;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy*2.0-1.0;
    uv.x *= resolution.x/resolution.y;
    
    float X = 0.3;
    mat3 rot = mat3(cos(X), sin(X), 0.0,
                   -sin(X), cos(X), 0.0,
                       0.0, 0.0, 1.0);
    vec3 origin = vec3(12.0,0.0,0.0);
    vec3 dir = -normalize(origin - vec3(0.0, uv)*4.);
    origin+=vec3(0.,0.,4.5);
    origin*=rot;
    dir*=rot;
    vec3 point = origin;
    vec3 pcolor = point;
    float angl;
    float mini = 10000.0;
    float mini2 = 1.0;
    float last1 = 0.0;
    float last2 = 0.0;
    for (int i = 0; i < 80; i++) {
        float dist = map2(point, pcolor, angl);
        mini=min(mini,dist);
        if (last2 > last1 && last1 < dist && i > 1) mini2 = min(mini2,mini);
        last2 = last1;
        last1 = dist;
        if(distance(point, origin)>30.0 || dist < 0.005) break;
        point += dir * dist;
    }
    angl*=4.;
    angl+=time*0.5*acos(-1.);
    mini2= min(atan((atan(mini2)-0.001*distance(point,origin))*80.0),1.0);
    uv*=30.;
    float checker = cos(uv.x)*cos(uv.y) < 0. ? 0.7 : 0.95;
    // Time varying pixel color
    vec3 col = vec3(sqrt(cos(length(pcolor.xy)*20.0)*0.4+0.5))*sqrt(vec3(cos(angl), sin(angl), -cos(angl))*0.45+0.7)*mini2;
    if(distance(point, origin)>30.0) col= vec3(checker*mini2);

    // Output to screen
    glFragColor = vec4(pow(sqrt(col)-0.2,vec3(1.5))*1.3,1.0);
}
