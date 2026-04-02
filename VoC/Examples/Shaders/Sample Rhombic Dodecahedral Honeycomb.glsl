#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tl2BD3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float FOV = 80.0;
const float MUL = tan(FOV * 3.14159265 / 180.0 / 2.0);
const int STEPS = 128;

vec4 trace(vec3 pos, vec3 dir);
bool check(vec3 pos);

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy * 2.0 - 1.0;
    uv.y *= resolution.y / resolution.x;
    
    vec2 mouse = (mouse*resolution.xy.xy / resolution.xy * 2.0 - 1.0);
    mouse.x *= 4.0;
    mouse.y *= 1.5;

    vec3 cameraPos = vec3(4. * time, 0, 4. * time);
    vec3 cameraDir = normalize(vec3(sin(mouse.x) * cos(mouse.y), sin(mouse.y), cos(mouse.x) * cos(mouse.y)));
    vec3 right = normalize(cross(vec3(0, 1, 0), cameraDir));
    vec3 up = cross(cameraDir, right);
    
    vec3 dir = normalize(cameraDir + up * MUL * uv.y + right * MUL * uv.x);
    
    
    vec4 traceData = trace(cameraPos, dir);
    float dist = traceData.w;
    vec3 collision = cameraPos + dist * dir;
    vec3 normal = traceData.xyz;
    //normal += texture(iChannel0, vec2(collision.x + collision.y, collision.x - collision.y) + (cameraPos + dist * dir).yz).xyz * 0.2;
    normal = normalize(normal);
    
    const vec3 skyColor = vec3(111, 168, 237) / 255.0;
    vec3 lightDir = normalize(vec3(-5.0 * cos(time / 5.0), -5, 5.0 * sin(time / 5.0)));
    
    glFragColor.xyz = mix(skyColor, vec3(1), pow(max(0.0, dot(dir, -lightDir)), 20.));
    
    if (dist != -1.0) {
        vec3 color = vec3(0.8, 0.2, 0.6);
        glFragColor.xyz = color * max(0.0, -dot(lightDir, normal));
        glFragColor.xyz = glFragColor.xyz * 0.8 + color * 0.2;
        
        vec3 reflectDir = normalize(reflect(dir, normal));
        float reflection = pow(max(0.0, dot(reflectDir, -lightDir)), 20.);
        glFragColor.xyz = mix(glFragColor.xyz, vec3(1), reflection);
        
        float fog = 1. - pow(0.98, dist);
        glFragColor.xyz = mix(glFragColor.xyz, skyColor, fog);
        
        
        
        //glFragColor.xyz = (normal + 2.) / 4.;
    }
}

vec4 trace(vec3 pos, vec3 dir) {
    vec3 step_p = vec3(1) / (dir.yzx + dir.zxy);
    vec3 step_n = vec3(1) / (dir.yzx - dir.zxy);
    
    vec3 samplePoint = floor(pos);
    if ((int(samplePoint.x + samplePoint.y + samplePoint.z) % 2) != 0) {
        vec3 fraction = fract(pos);
        vec3 _sign = vec3(lessThan(fraction, 1. - fraction)) * 2. - 1.;
        fraction = min(fraction, 1. - fraction);
        if (fraction.x < fraction.y && fraction.x < fraction.z) {
            samplePoint.x -= _sign.x;
        }
        else if (fraction.y < fraction.z) {
            samplePoint.y -= _sign.y;
        }
        else
            samplePoint.z -= _sign.z;
    }
    
    vec3 next_p = samplePoint.yzx + samplePoint.zxy + 1. + 1. * sign(step_p);
    vec3 next_n = samplePoint.yzx - samplePoint.zxy + sign(step_n);
    
    vec3 dist_p = abs((next_p - pos.yzx - pos.zxy) / (dir.yzx + dir.zxy));
    vec3 dist_n = abs((next_n - pos.yzx + pos.zxy) / (dir.yzx - dir.zxy));
    
    float minDist;
    vec3 normal;
    float _sign;
    float totalDist = 0.0;
    
    for(int i = 0; i < STEPS; ++i) {
        minDist = min(dist_p.z, min(dist_p.x, min(dist_p.y, min(dist_n.z, min(dist_n.x, dist_n.y)))));
        
        if (dist_p.z == minDist) {
            _sign = sign(step_p.z);
            
            dist_p += step_p * _sign - minDist;
            dist_n += step_n * _sign * vec3(1, -1, 0) - minDist;
            dist_p.z = 2.0 * abs(step_p.z);
            totalDist += minDist;
            
            normal = -_sign * vec3(1, 1, 0);
        }
        else if (dist_n.z == minDist) {
            _sign = sign(step_n.z);
            
            dist_p += step_p * _sign * vec3(-1, 1, 0) - minDist;
            dist_n += -step_n * sign(step_n.z) - minDist;
            dist_n.z = 2.0 * abs(step_n.z);
            totalDist += minDist;
            
            normal = -_sign * vec3(1, -1, 0);
        }
        else if (dist_p.x == minDist) {
            _sign = sign(step_p.x);
            
            dist_p += step_p * _sign - minDist;
            dist_n += step_n * _sign * vec3(0, 1, -1) - minDist;
            dist_p.x = 2.0 * abs(step_p.x);
            totalDist += minDist;
            
            normal = -_sign * vec3(0, 1, 1);
        }
        else if (dist_n.x == minDist) {
            _sign = sign(step_n.x);
            
            dist_p += step_p * _sign * vec3(0, -1, 1) - minDist;
            dist_n += -step_n * sign(step_n.x) - minDist;
            dist_n.x = 2.0 * abs(step_n.x);
            totalDist += minDist;
            
            normal = -_sign * vec3(0, 1, -1);
        }
        else if (dist_p.y == minDist) {
            _sign = sign(step_p.y);
            
            dist_p += step_p * _sign - minDist;
            dist_n += step_n * _sign * vec3(-1, 0, 1) - minDist;
            dist_p.y = 2.0 * abs(step_p.y);
            totalDist += minDist;
            
            normal = -_sign * vec3(1, 0, 1);
        }
        else {
            _sign = sign(step_n.y);
            
            dist_p += step_p * _sign * vec3(1, 0, -1) - minDist;
            dist_n += -step_n * sign(step_n.y) - minDist;
            dist_n.y = 2.0 * abs(step_n.y);
            totalDist += minDist;
            
            normal = -_sign * vec3(-1, 0, 1);
        }
        samplePoint -= normal;
        
        if (check(samplePoint)) return vec4(normal * 0.70710678118, totalDist);
    }

    
    
    
    return vec4(-1);
    
}

bool check(vec3 pos) {
        return (pos.y + sin(pos.x) / 2. + sin(pos.z / 2.) / 2. + 10. * sin(pos.x / 20.) * sin(pos.z / 20.) < -3.);
}
