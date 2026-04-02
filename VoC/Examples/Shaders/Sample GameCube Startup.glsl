#version 420

// original https://www.shadertoy.com/view/4dtyzN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int MAX_MARCHING_STEPS = 60;
const float MIN_DIST = 0.0;
const float MAX_DIST = 30.0;
const float EPSILON = 0.001;
const float M_PI = 3.14159265359;
const float SPEED = 6.0;

vec3 transform( vec3 p, mat4 m ) {
    vec3 q = (inverse(m)*vec4(p,1)).xyz;
    return q;
}

float dot2( in vec3 v ) { return dot(v,v); }
float quadSDF( vec3 p, vec3 a, vec3 b, vec3 c, vec3 d ) {
    vec3 ba = b - a; vec3 pa = p - a;
    vec3 cb = c - b; vec3 pb = p - b;
    vec3 dc = d - c; vec3 pc = p - c;
    vec3 ad = a - d; vec3 pd = p - d;
    vec3 nor = cross( ba, ad );

    return sqrt(
    (sign(dot(cross(ba,nor),pa)) +
     sign(dot(cross(cb,nor),pb)) +
     sign(dot(cross(dc,nor),pc)) +
     sign(dot(cross(ad,nor),pd))<3.0)
     ?
     min( min( min(
     dot2(ba*clamp(dot(ba,pa)/dot2(ba),0.0,1.0)-pa),
     dot2(cb*clamp(dot(cb,pb)/dot2(cb),0.0,1.0)-pb) ),
     dot2(dc*clamp(dot(dc,pc)/dot2(dc),0.0,1.0)-pc) ),
     dot2(ad*clamp(dot(ad,pd)/dot2(ad),0.0,1.0)-pd) )
     :
     dot(nor,pa)*dot(nor,pa)/dot2(nor) );
}

float squareSDF( vec3 p, vec3 o, float s, int x ) {
    s /= 2.0;
    vec3 a,b,c,d;
    if(x == 0) {
        a = o-vec3(s*1.414,0,s*1.414);
        b = o+vec3(s*-1.414,0,s*1.414);
        c = o+vec3(s*1.414,0,s*1.414);
        d = o+vec3(s*1.414,0,s*-1.414);
    } else if(x == 1) {
        a = o-vec3(s*1.414,s*1.414,0);
        b = o+vec3(s*-1.414,s*1.414,0);
        c = o+vec3(s*1.414,s*1.414,0);
        d = o+vec3(s*1.414,s*-1.414,0);
    } else {
        a = o-vec3(0,s*1.414,s*1.414);
        b = o+vec3(0,s*-1.414,s*1.414);
        c = o+vec3(0,s*1.414,s*1.414);
        d = o+vec3(0,s*1.414,s*-1.414);
    }
    return quadSDF(p,a,b,c,d);
}

const int sqaxes[17] = int[17](
      0,0,0,0,1,1,1,1,1,1,2,2,2,2,2,2,2);

float gsquaresSDF( vec3 p ) {
    float result = MAX_DIST+1.0;
    vec3 start = vec3(-2.5,-0.1,-4);
    vec3 offs[17] = vec3[17]( vec3(0),
        vec3(-1.6, 0, 0), vec3(-1.6, 0, 1.6),
        vec3(-1.6, 0, 3.2), vec3(0), vec3(-2.5, -1.5, 3.3),
        vec3(-2.5, -3.1, 3.3), vec3(-2.5, -4.7, 3.3),
        vec3(-0.9, -4.7, 3.3), vec3(0.7, -4.7, 3.3), vec3(0),
        vec3(1.5, -4.7, 2.5), vec3(1.5, -4.7, 0.9),
        vec3(1.5, -4.7, -0.7), vec3(1.5, -3.1, -0.7),
        vec3(1.5, -1.5, -0.7), vec3(1.5, -1.5, 0.9));
    
    int num = min(int(mod(floor(time*SPEED),23.0)), 17);
    for(int i = 0; i < num; i++) {
        if(i == 0 || sqaxes[i] == sqaxes[i-1]) {
            result = min(result, squareSDF(p,start+offs[i],1.0,sqaxes[i]));
        }
    }
    return result;
}

float spincubeSDF( vec3 p ) {
    float cosTheta = cos(fract(time*SPEED)*M_PI*0.5);
    float sinTheta = sin(fract(time*SPEED)*M_PI*0.5);
    
    mat4 rotx = mat4(1, 0, 0, 0,
                     0, cosTheta, sinTheta, 0,
                     0, -sinTheta, cosTheta, 0,
                      0, 0, 0, 1);
    mat4 roty = mat4(cosTheta, 0, -sinTheta, 0,
                     0, 1, 0, 0,
                     sinTheta, 0, cosTheta, 0,
                      0, 0, 0, 1);
    mat4 roty2 = mat4(cosTheta, 0, sinTheta, 0,
                     0, 1, 0, 0,
                     -sinTheta, 0, cosTheta, 0,
                      0, 0, 0, 1);
    mat4 rotz = mat4(cosTheta, sinTheta, 0, 0,
                     -sinTheta, cosTheta, 0, 0,
                     0, 0, 1, 0,
                      0, 0, 0, 1);
    mat4 roti = mat4(1, 0, 0, 0,
                     0, 1, 0, 0,
                     0, 0, 1, 0,
                      0, 0, 0, 1);
    
    vec3 pos = vec3(-0.9,0.5,-4);
    vec3 scale = vec3(0.6);
    int num = min(int(mod(floor(time*SPEED),23.0)), 21);
    mat4 rotm;
    vec3 rotp;
    if(num < 2) {
        pos.x -= float(num)*1.6;
        rotm = rotz;
        rotp = vec3(0.8,0.8,0);
    } else if(num < 5) {
        pos.x -= 3.2;
        pos.z += float(num-2)*1.6;
        rotm = rotx;
        rotp = vec3(0,0.8,-0.8);
    } else if(num < 8) {
        pos.x -= 3.4;
        pos.z += 4.5;
        pos.y -= -0.2 + float(num-5)*1.6;
        rotm = rotx;
        rotp = vec3(0,0.8,0.8);
    } else if(num < 11) {
        pos.x -= 3.4 - float(num-8)*1.6;
        pos.z += 4.6;
        pos.y -= 4.6;
        rotm = roty;
        rotp = vec3(-0.8,0,0.8);
    } else if(num < 14) {
        pos.x += 1.0;
        pos.z += 4.6 - float(num-11)*1.6;
        pos.y -= 5.0;
        rotm = roty;
        rotp = vec3(0.8,0,0.8);
    } else if(num < 16) {
        pos.x += 0.7;
        pos.z -= 0.8;
        pos.y += float(num-14)*1.6 - 5.0;
        rotm = rotz;
        rotp = vec3(0.8,-0.8,0);
    } else if(num < 17) {
        pos.x += 0.7;
        pos.z += float(num-16)*1.6-0.5;
        pos.y += -1.8;
        rotm = roty2;
        rotp = vec3(0.8,0,-0.8);
    } else if(num < 20){
        float off = mod(time*SPEED,23.0)-17.0;
        pos.x = -0.2;
        pos.z += min(1.1 + off, 3.8);
        pos.y += max(-1.8 + sin(off*1.0)*5.0, -1.8);
        rotm = inverse(roty)*rotx;
        rotp = vec3(0);
    } else {
        pos = vec3(-0.2);
        rotm = roti;
        rotp = vec3(0);
        scale = vec3(0.8);
    }
    
    p -= pos;
    p = transform(p+rotp, rotm);
    p -= rotp;
    return length(max(abs(p)-scale,0.0))-0.07;
}

float sceneSDF(vec3 pos) {
    return min(spincubeSDF(pos), gsquaresSDF(pos));
}

float shortestDistance(vec3 eye, vec3 marchingDirection) {
    float depth = MIN_DIST;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        float dist = sceneSDF(eye + depth * marchingDirection);
        if (dist < EPSILON) {
            return depth;
        }
        depth += dist;
        if (depth >= MAX_DIST) {
            return MAX_DIST;
        }
    }
    return MAX_DIST;
}
            
vec3 rayDirection(float fieldOfView, vec2 size, vec2 gl_FragCoord) {
    vec2 xy = gl_FragCoord.xy - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

vec3 getNormal(vec3 p) {
    if(spincubeSDF(p) > EPSILON) {
        return vec3(0,1,0);
    }
    return normalize(vec3(
        spincubeSDF(vec3(p.x + EPSILON, p.y, p.z)) - sceneSDF(vec3(p.x - EPSILON, p.y, p.z)),
        spincubeSDF(vec3(p.x, p.y + EPSILON, p.z)) - sceneSDF(vec3(p.x, p.y - EPSILON, p.z)),
        spincubeSDF(vec3(p.x, p.y, p.z  + EPSILON)) - sceneSDF(vec3(p.x, p.y, p.z - EPSILON))
    ));
}

mat4 viewMatrix(vec3 eye, vec3 center, vec3 up) {
    vec3 f = normalize(center - eye);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat4(
        vec4(s, 0.0),
        vec4(u, 0.0),
        vec4(-f, 0.0),
        vec4(0.0, 0.0, 0.0, 1)
    );
}

void main(void) {
    vec3 viewDir = rayDirection(45.0, resolution.xy, gl_FragCoord.xy);
    vec3 eye = vec3(9.0);
    
    if(mod(time*SPEED,23.0) > 20.0) {
        eye.y += max(sin((mod(time*SPEED,23.0)-20.0)*M_PI*0.5)*2.5, -0.5);
    }
    
    mat4 viewToWorld = viewMatrix(eye, vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0));
    
    vec3 worldDir = (viewToWorld * vec4(viewDir, 0.0)).xyz;
    
    float dist = shortestDistance(eye, worldDir);
    
    if (dist > MAX_DIST - EPSILON) {
        glFragColor = vec4(0.0, 0.0, 0.0, 0.0);
        return;
    }
    
    vec3 p = eye + dist * worldDir;
    
    vec3 color = vec3(0.2588, 0.1608, 0.6706);
    float diffuseTerm = 1.0;
    vec3 specularColor = vec3(1.0, 1.0, 1.0);
    float shininess = 10.0;
    vec3 light = vec3(5,3,7);
    vec4 refl = normalize(normalize(vec4(eye,1.0)-vec4(p,1))+normalize(vec4(light,1)));
    float specularTerm = pow(max(dot(refl,vec4(getNormal(p),1)),0.0),shininess);
    
    glFragColor = vec4(color * diffuseTerm + specularColor * specularTerm,1);
}
