#version 420

// original https://www.shadertoy.com/view/3tSBDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//base on: https://github.com/patriciogonzalezvivo/thebookofshaders

float random (in vec2 _st) {
    return fract(sin(dot(_st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

// Based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
//四点插值噪声
float noise (in vec2 _st) {
    vec2 i = floor(_st);
    vec2 f = fract(_st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

#define NUM_OCTAVES 6
//fbm函数，其中增加了一个旋转的叠加
float fbm ( in vec2 _st) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    // Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5),
                    -sin(0.5), cos(0.50));
    for (int i = 0; i < NUM_OCTAVES; ++i) {
        v += a * noise(_st);
        _st = rot * _st * 5.0 + shift;
        a *= 0.5;
    }
    return v;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    //vec2 uv = gl_FragCoord.xy/resolution.xy;

    // Time varying pixel color
    //vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));

    // Output to screen
    //glFragColor = vec4(col,1.0);

    vec2 st = gl_FragCoord.xy/resolution.xy*3.;
    st.x *= resolution.x / resolution.y;
    
    vec3 color = vec3(0.0);

    vec2 q = vec2(0.);
    q.x = fbm( st + 0.00*time);
    q.y = fbm( st + vec2(1.0));

    //用fbn来实现对fbm参数的初始化，
    //也就是说fbm嵌套fbm
    vec2 r = vec2(0.);
    r.x = fbm( st + 1.0*q + vec2(1.7,9.2)+ 0.15*time );
    r.y = fbm( st + 1.0*q + vec2(8.3,2.8)+ 0.126*time);

    //可以改变f的取值方式，来观察有什么不同的效果
    float f = fbm(r);
    f = fbm(st * r);

    //使用f的二次函数值作为alpha
    //进行双色插值
    color = mix(vec3(0.0745, 0.6667, 0.7216),
                vec3(0.2078, 0.9333, 0.898),
                clamp((f*f)*4.0,0.0,1.0));

    //使用q的模作为alpha   
    //进行color与单色插值
    color = mix(color,
                vec3(0,0,0.164706),
                clamp(length(q),0.0,1.0));

    //使用r.x的clamp值作为alpha
    //进行color与单色插值
    color = mix(color,
                vec3(0.702, 1.0, 0.9765),
                clamp(length(r.x),0.0,1.0));

    //使用f的三次函数对color进行后期处理
    glFragColor = vec4((f*f*f+.6*f*f+.5*f)*color,1.);
    //使用平方进行锐化
    glFragColor = vec4(color * color, 1.0);
    //
    //glFragColor = vec4(sin(u_time) * color, 1.0);
    
}
