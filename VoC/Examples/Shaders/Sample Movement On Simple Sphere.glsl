#version 420

// original https://www.shadertoy.com/view/WtcGRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// References
// https://www.shadertoy.com/view/XdfczH
// https://www.shadertoy.com/view/wtfSWH
// https://www.shadertoy.com/view/tslXRj
// http://www.sousakuba.com/Programming/gs_two_lines_intersect.html

#define pi 3.14159265358979323846264338327950288419716

vec3 moveOnSphereThetaPhi(float radius, float theta, float phi) {
    //theta = (mod(lon,360.0) / 360.0)*pi * 2.0;
    //phi = (mod(lat,360.0) / 360.0)*pi * 2.0;
    theta = theta * pi;
    phi = phi * pi;
    float tsin = sin(theta);
    return radius * vec3(tsin*cos(phi),tsin*sin(phi),cos(theta));
}

vec3 moveOnSphereLonLat(float radius, float lon, float lat) {
    //vec3 pos = vec3(0.0,0.0,0.0);
    //float lat = asin(pos.z / radius);
    //float lon = atan(pos.y,pos.x);
  
    float x = cos(lat) * cos(lon);
    float y = cos(lat) * sin(lon);
    float z = sin(lat);

    vec3 move = radius * vec3(x,y,z);
            
    return move;
}

float circle(vec2 gl_FragCoord, float radius)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 cUv = uv;
    cUv.x -= 0.5;
    cUv.y -= 0.5;
    cUv.y *= resolution.y/resolution.x;
    
    float circleOuter = smoothstep(0.101,0.103,length(cUv*0.5)/radius);
    float circleInner = smoothstep(0.099,0.097,length(cUv*0.5)/radius);
    float circle = circleInner + circleOuter;

    float c = 1.0 - circle;

    return c;
}

float DistLine(vec3 ro, vec3 rd, vec3 p) {
    return length(cross(p-ro, rd))/length(rd);
}

float DrawPoint(vec3 ro, vec3 rd, vec3 p) {
    float d = DistLine(ro, rd, p);
    d = smoothstep(.06, .05, d);
    float z = p.z > 0.0 ? 0.125 : 1.0;
        
    return d*z;
}

float DrawLine(vec3 ro, vec3 rd, vec3 a, in vec3 b)
{
    vec3 ab =normalize(b-a),ao = a-ro;
    float d0 = dot(rd, ab), d1 = dot(rd, ao), d2 = dot(ab, ao);
    float len = (d0*d1-d2)/(1.0-d0*d0);
    len= clamp(len,0.0,length(b-a));
    vec3 p = a+ab*len;
    float z = p.z > 0.0 ? 0.0 : 1.0;
    
     //float d = DistLine(ro, rd, p);
    //d = smoothstep(.06, .05, d);
    //float z = p.z > 0.0 ? 0.125 : 1.0;
    
    return length(cross(p-ro, rd))/(1.-p.z);
}

vec3 lookat(vec3 p, vec3 eye, vec3 target, vec3 up)
{
    vec3 w = normalize(target-eye), u = normalize(cross(w,up));
    return vec3(dot(p,u), dot(p,cross(u,w)), dot(p,w));
}

void main(void)
{
    float t = time;
    
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 muv = uv;
    
    muv -= 0.5;
    muv.x *= resolution.x/resolution.y;
    
    vec3 target = vec3(0.0, 0.0, 0.0);
    vec3 ro = vec3(3. * cos(t)*0.0, 2. * sin(t)*0.0, -3.); // camera position
    
    float zoom = 1.0;
    
    vec3 up = vec3(0., 1., 0.);
    vec3 f = normalize(target - ro);
    vec3 r = cross(up, f);
    vec3 u = cross(f, r);
    
    vec3 z = ro + f * zoom;
    vec3 i = z + muv.x*r + muv.y*u;
    vec3 rd = normalize(i - ro); // camera direction
    vec3 rd2 = lookat(rd,ro,target,up);
    //rd=vec3(muv, 1.0);
    
    vec3 p = vec3(0);
    
    vec3 mover = vec3(0);
    
    vec3 o = moveOnSphereLonLat(1.,t,t*2.);
    vec3 du = o+normalize(o)*.2;
    vec3 df = moveOnSphereLonLat(1.,(t+.1)*1.0,(t+.1)*2.);
    vec3 dr = o+cross(du,df);
    
    float lu = .01/DrawLine(ro, rd, o, du);
    float lf = .01/DrawLine(ro, rd, o, df);
    float lr = .01/DrawLine(ro, rd, o, dr);
    
    mover += vec3(DrawPoint(ro, rd, o));
    mover += mix(mover,vec3(0.,0.,1.),lu);
    mover += vec3(1.,0.,0)*lf;
    mover += vec3(0.,1.,0.)*lr;
    
    for(int i=0; i<50; i++) {
        float j = float(i)*.04;
        mover += DrawPoint(ro, rd,  moveOnSphereLonLat(1.,(t-j),(t-j)*2.));
    }
    
    vec3 col = vec3(0);
    col = vec3(circle(gl_FragCoord.xy,0.9))*.35 + mover;
    
    glFragColor = vec4(col,1.);
}
