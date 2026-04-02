#version 420

// original https://www.shadertoy.com/view/7tsGzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// shape control
#define GRIDS 3.
#define ITER 5.

// 1/SPEED seconds per round
#define ROTATE_SPEED  0.05

#define PI 3.14159265
#define SQRT2 1.41421356

float Ring(vec2 uv, vec2 o, float r, float width) {
    float dist = distance(uv, o);
    return abs(dist - (r - width));
}

float sdCircle(vec2 uv, vec2 o, float r, float blur) {
    float dist = distance(uv, o);
    return smoothstep(r, r-0.5-blur, dist);
}

//  Function from Iñigo Quiles
//  https://www.shadertoy.com/view/MsS3Wc
vec3 hsb2rgb( in vec3 c ){
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                             6.0)-3.0)-1.0,
                     0.0,
                     1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix( vec3(1.0), rgb, c.y);
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy * 2. - resolution.xy) / resolution.y;
    
    float blur = 3. / resolution.y;
    float mask = 0.;
    float rotate_speed = ROTATE_SPEED;
    float grids = GRIDS;
    float part_id = 0.;
    vec3 bg = vec3(0.);
    
    float angle;
    float dist = length(uv);
    bg = hsb2rgb(vec3(1./9., dist, 1.0));
    vec3 last_color = vec3(0.);
    for (float i = 0.; i < ITER; ++i) {
        
        float angle = atan(uv.y, uv.x);
        
        // angle = Remap(-PI, PI, 0., 1., angle);
        angle = angle / (2. * PI) + 0.5;
        
        // align angle = 0 to +Y axis, totate by time
        // angle = 0 对齐到 x正轴，追加一些旋转
        angle = fract(angle + 0.5 + time * rotate_speed);

        // divide area by angle
        // 等分角度
        grids = GRIDS + part_id;
        part_id = floor(angle * grids);
        float part_angle = fract(angle * grids);
        
        float every_other = mod(part_id, 2.0) * 2.0 - 1.0;
        rotate_speed *= every_other * 2.0;
        
        // inverse map uv
        // 将网格化后的角度重新映射回笛卡尔坐标
        vec2 guv = vec2(cos(part_angle / grids * 2. * PI), sin(part_angle / grids * 2. * PI)) * dist;

        // map uv to BBox of the inner circle of current sub area, circle radius become 1
        // gr是(guv区域并uv大圆的)内接圆
        // guv从[0,1]映射到以内接圆为中心的坐标，内接圆半径长度是1
        float theta = 2. * PI / grids;
        float S = sin(theta * 0.5);
        float gr = S/(1.+S);
        vec2 go = vec2(sqrt(1.-2.*gr), gr);
        
        // 坐标映射
        uv = (guv - go) / gr;
        dist = length(uv);
        
        // scale blur along with uv
        // 坐标缩放后blur需要变粗
        blur /= gr;
        
        // mix colors        
        float compX = part_id / grids;
        last_color = hsb2rgb(vec3(compX, dist, 1.0));
        bg = bg * 0.75 + last_color * sdCircle(uv, vec2(0.), 1., blur) * 0.5;
    }
    
    float width = 0.01;
    float ring = Ring(uv, vec2(0.), 1., width);
    // mask = ring;
    mask += smoothstep(width+blur, width, ring);
    
    vec3 color = vec3(0.);
    color += bg;
    color += last_color * mask;

    glFragColor = vec4(color,1.0);
}
