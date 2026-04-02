#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sdSphere(vec3 p, float rad) {
    return length(p)-rad;
}

//https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float opSmoothSubtraction( float d1, float d2, float k ) {
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h);
}

float sdApple(vec3 p, float rad) {
    float val = sdSphere(p, rad);
    val = opSmoothSubtraction(sdSphere(p-vec3(0.0,rad,0.0), rad/3.0), val, 1.0);
    val = opSmoothSubtraction(sdSphere(p-vec3(0.0,-rad,0.0), rad/5.0), val, 0.5);
    return val;
}

vec4 opUnion(vec4 a, vec4 b) {
    if(a.w == b.w) {
        vec3 col = mix(a.rgb,b.rgb, 0.5);
        return vec4(col, a.w);
    } else if(a.w < b.w) {
        return a;
    } else {
        return b;
    }
}

vec4 opIntersect(vec4 a, vec4 b) {
    if(a.w == b.w) {
        vec3 col = mix(a.rgb,b.rgb, 0.5);
        return vec4(col, a.w);
    } else if(a.w > b.w) {
        return a;
    } else {
        return b;
    }
}

vec4 opCut(vec4 a, vec4 b) {
    return opIntersect(a, vec4(b.rgb,-b.w));
}

vec4 scene(vec3 p) {
    vec4 res = vec4(vec3(0.0),100.0);
    {
        vec3 op = p;
        vec3 sphereOrigin = vec3(0.0,0.0,3.0);
        float sphereRad = 1.0;
        float angle = time;
        vec3 offset = sphereOrigin;
        p -= offset;
        p = vec3(p.x*cos(angle)-p.z*sin(angle), p.y, p.z*cos(angle)+p.x*sin(angle));
        p += offset;
        vec3 sphereColor = vec3(1.0,0.0,0.0);
        vec4 sphereRes = vec4(sphereColor, sdApple(p-sphereOrigin, sphereRad));
        if(sphereRes.w < sphereOrigin.z+sphereRad*1.1) {
        
        for(int i = 0; i < 20; ++i){
            if(float(i) > mod(time, 20.0)) {
                break;
            }
            float bigVal = float(i)*100.0+125.0;
            vec3 surf = normalize(vec3(sin(bigVal*213.4),cos(bigVal*7363.2),sin(bigVal*73428.1)));
            vec3 smallSphereOrigin = sphereOrigin+surf*sphereRad;
            float smallSphereRad = 0.5;
            sphereRes = opCut(sphereRes, vec4(vec3(1.0,1.0,0.5), sdSphere(p-smallSphereOrigin, smallSphereRad)));    
        }
        }
        res = opUnion(res, sphereRes);
        p = op;
    }
    
    return res;
}

//https://www.iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 calcNormal( in vec3 p ) // for function f(p)
{
    const float eps = 0.0001; // or some other value
    const vec2 h = vec2(eps,0);
    vec3 normal = vec3(scene(p+h.xyy).w - scene(p-h.xyy).w,scene(p+h.yxy).w - scene(p-h.yxy).w,scene(p+h.yyx).w - scene(p-h.yyx).w);
    return normalize( normal);
}

void main( void ) {

    vec2 position = ( gl_FragCoord.xy / resolution.xy );
    
    position -= vec2(0.5);
    position.x /= resolution.y/resolution.x;
    
    
    vec3 rayOrigin = vec3(0.0,1.0,0.0);
    vec3 rayDir = normalize(vec3(position, 1.0));
    float downAngle = 0.3;
    rayDir.yz = vec2(rayDir.y*cos(downAngle)-rayDir.z*sin(downAngle), rayDir.z*cos(downAngle)+rayDir.y*sin(downAngle));
    
    vec4 result;
    vec3 pos = rayOrigin;
    for(int i = 0; i < 50; ++i) {
        result = scene(pos);
        if(result.w < 0.0001) {
            break;
        }
        pos = pos+result.w*rayDir;
    }
    
    //normals
    vec3 normal = calcNormal(pos);
    
    vec3 color = result.rgb;
    float ambient = 0.2;
    color *= mix(clamp(dot(normal, normalize(vec3(1.0,0.5,-1.0))), 0.0,1.0), 1.0,ambient);
    
    color = pow(color, vec3(0.75));

    glFragColor = vec4( color, 1.0 );

}
