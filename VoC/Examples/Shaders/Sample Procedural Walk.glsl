#version 420

// original https://www.shadertoy.com/view/ssdGzX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float movement_speed = 4.7;

const vec2 legs_origin = vec2(0.885, 0.06);
const float legs_radius = 0.07;
const float legs_height_clamp = 0.01;

const vec2 pelvis_origin_initial = vec2(0.7105, 0.62);
const float upper_knee_length = 0.32;
const float lower_knee_length = 0.32;

const float torso_height = 0.35;
const float neck_height = 0.13;
const float shoulder_length = 0.22;
const float forearm_length = 0.21;

float circle(in vec2 uv, in vec2 p, in float rad)
{
    float linear_eps = 1.0 / resolution.x;
    vec2 puv = uv - p;
    return smoothstep(rad + linear_eps, rad - linear_eps, length(puv));
}

float sd_segment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

float line(in vec2 uv, in vec2 p1, in vec2 p2, in float rad)
{
    float linear_eps = 1.0 / resolution.x;
    return smoothstep(rad + linear_eps, rad - linear_eps, sd_segment(uv, p1, p2));
}

vec2 rotate(in vec2 v, in float theta)
{
    vec2 sincos = vec2(sin(theta), cos(theta));
    mat2x2 rot = mat2x2(
        sincos.y, sincos.x,
        -sincos.x, sincos.y
    );
    return rot * v;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.x;
    
    vec3 col = vec3(0.5, 0.5, 0.5);
    
    float l1 = lower_knee_length;
    float l2 = upper_knee_length;
    
    vec2 k2 = vec2(l1*l1 - l2*l2);
    
    vec2 sincos = vec2(
        sin(time * movement_speed), 
        cos(time * movement_speed)
    );
    vec2 sincos2 = vec2(
        sin(time * movement_speed * 2.0),
        cos(time * movement_speed * 2.0)
    );
    
    vec2 fwd_v = normalize(vec2(-0.42, -1.0)) * (l1 + l2);
    
    
    float shoulder_angle_left = -sincos.x / 7.0;
    float forearm_angle_left = shoulder_angle_left + shoulder_angle_left;
    float shoulder_angle_right = sincos.x / 7.0;
    float forearm_angle_right = shoulder_angle_right + shoulder_angle_right;
    
    vec2 pelvis_origin = pelvis_origin_initial;
        
    vec2 torso = pelvis_origin 
        + vec2(0.0, torso_height)
        - vec2(
            sincos2.x * 0.006, 
            sincos2.y * 0.002
        );
    
    vec2 neck = torso 
        + vec2(0.0, neck_height)
        + vec2(
            sincos2.x * 0.001, 
            sincos2.y * 0.001
        );
        
    vec2 elbow_left = torso +
        rotate(vec2(0.0, -shoulder_length), shoulder_angle_left);
    vec2 palm_left = elbow_left +
        rotate(vec2(0.0, -forearm_length), forearm_angle_left);
    vec2 elbow_right = torso +
        rotate(vec2(0.0, -shoulder_length), shoulder_angle_right);
    vec2 palm_right = elbow_right +
        rotate(vec2(0.0, -forearm_length), forearm_angle_right);
        
    //float shoulder
    
    vec2 v_left = legs_origin + sincos.xy * legs_radius;
    vec2 v_right = legs_origin - sincos.xy * legs_radius;
    
    v_left = mix(v_left, pelvis_origin + fwd_v, (1.0 - sincos.x) / 2.0);
    v_left.y = max(legs_height_clamp, v_left.y);
    
    
    v_right = mix(v_right, pelvis_origin + fwd_v, (sincos.x + 1.0) / 2.0);
    v_right.y = max(legs_height_clamp, v_right.y);
    
    pelvis_origin += 
        vec2(
            sincos2.x * 0.001, 
            sincos2.y * 0.005
        );
    
    vec2 dir_left = v_left - pelvis_origin;
    vec2 dir_right = v_right - pelvis_origin;
    
    vec2 k1 = vec2(
        length(dir_left),
        length(dir_right)
    );
    
    dir_left = normalize(dir_left);
    dir_right = normalize(dir_right);
    
    
    if (k1.x > l1 + l2) {
        k1.x = l1 + l1;
        v_left = pelvis_origin + dir_left * (l1 + l2);
    }
    
    if (k1.y > l1 + l2) {
        k1.y = l1 + l1;
        v_right = pelvis_origin + dir_right * (l1 + l2);
    }
  
    vec2 d = (k1*k1 - k2) / (2.0 * k1);
    vec2 cos_a = d / l2;
    vec2 a = acos(cos_a);
    
    mat2x2 rot_left = mat2x2(
        cos_a.x, sin(a.x),
        -sin(a.x), cos_a.x
    );
    mat2x2 rot_right = mat2x2(
        cos_a.y, sin(a.y),
        -sin(a.y), cos_a.y
    );
    
    vec2 knee_left = (rot_left * dir_left) * l2 + pelvis_origin;
    vec2 knee_right = (rot_right * dir_right) * l2 + pelvis_origin;
    
    neck /= 2.2;
    torso /= 2.2;
    pelvis_origin /= 2.2;
    knee_left /= 2.2;
    knee_right /= 2.2;
    v_left /= 2.2;
    v_right /= 2.2;
    elbow_left /= 2.2;
    elbow_right /= 2.2;
    palm_left /= 2.2;
    palm_right /= 2.2;
    
    col = mix(
        col, vec3(0.8, 0.8, 0.8), 
        line(uv, torso, neck, 0.002)
    );
    
    col = mix(
        col, vec3(0.8, 0.8, 0.8), 
        line(uv, pelvis_origin, torso, 0.002)
    );
    
    col = mix(
        col, vec3(0.8, 0.8, 0.8), 
        line(uv, pelvis_origin, knee_left, 0.002)
    );
    col = mix(
        col, vec3(0.8, 0.8, 0.8), 
        line(uv, knee_left, v_left, 0.002)
    );
    
    col = mix(
        col, vec3(0.8, 0.8, 0.8), 
        line(uv, pelvis_origin, knee_right, 0.002)
    );
    col = mix(
        col, vec3(0.8, 0.8, 0.8), 
        line(uv, knee_right, v_right, 0.002)
    );
    
    col = mix(
        col, vec3(0.8, 0.8, 0.8), 
        line(uv, torso, elbow_left, 0.002)
    );
    col = mix(
        col, vec3(0.8, 0.8, 0.8), 
        line(uv, elbow_left, palm_left, 0.002)
    );
    col = mix(
        col, vec3(0.8, 0.8, 0.8), 
        line(uv, torso, elbow_right, 0.002)
    );
    col = mix(
        col, vec3(0.8, 0.8, 0.8), 
        line(uv, elbow_right, palm_right, 0.002)
    );
    
    col = mix(col, vec3(1.0, 1.0, 1.0), circle(uv, neck, 0.04));
    
    col = mix(col, vec3(1.0, 1.0, 1.0), circle(uv, pelvis_origin, 0.01));
    col = mix(col, vec3(1.0, 1.0, 1.0), circle(uv, torso, 0.01));
    
    col = mix(col, vec3(0.88, 0.4, 0.47), circle(uv, knee_left, 0.005));
    col = mix(col, vec3(0.47, 0.4, 0.88), circle(uv, knee_right, 0.005));
    
    col = mix(col, vec3(0.88, 0.4, 0.47), circle(uv, elbow_left, 0.005));
    col = mix(col, vec3(0.47, 0.4, 0.88), circle(uv, elbow_right, 0.005));
    
    col = mix(col, vec3(0.88, 0.4, 0.47), circle(uv, palm_left, 0.005));
    col = mix(col, vec3(0.47, 0.4, 0.88), circle(uv, palm_right, 0.005));
    
    col = mix(col, vec3(0.88, 0.4, 0.47), circle(uv, v_left, 0.005));
    col = mix(col, vec3(0.47, 0.4, 0.88), circle(uv, v_right, 0.005));
    
    
    glFragColor = vec4(col,1.0);
}
