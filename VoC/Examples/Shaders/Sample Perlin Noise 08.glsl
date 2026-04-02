#version 420

// original https://www.shadertoy.com/view/3ljyRy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 hash22(vec2 p)
{
    p = vec2( dot(p,vec2(612.1,946.7)),
              dot(p,vec2(735.5,354.3)));
    
    float time = time * 1.0;
    vec2 rotVec0 = vec2(cos(time), -sin(time));
    vec2 rotVec1 = vec2(sin(time), cos(time));
    mat2 rot = mat2(rotVec0,rotVec1);

    vec2 vertexDir = -1.0 + 2.0 * fract(sin(p)*(43758.5453));
    //以下是以旋转梯度向量的方式让纹理动起来，但是会出现周期性
    //还有种让纹理动起来的方式是用更高维度的噪音图，其中一个维度是时间维度
    vertexDir = normalize(rot * vertexDir);
    return vertexDir;
}
float perlin_noise(vec2 p)
{
    vec2 pi = floor(p);
    vec2 pf = p - pi;
    
    //以下两个是前人提出的缓和曲线
    //vec2 w = pf * pf * (3.0 - 2.0 * pf);    //一阶导数连续
    vec2 w = pf * pf * pf * (pf * pf * 6.0 - pf * 15.0 + 10.0);    //二阶导数连续

    return mix(mix(dot(hash22(pi + vec2(0.0, 0.0)), pf - vec2(0.0, 0.0)), 
                   dot(hash22(pi + vec2(1.0, 0.0)), pf - vec2(1.0, 0.0)), w.x), 
               mix(dot(hash22(pi + vec2(0.0, 1.0)), pf - vec2(0.0, 1.0)), 
                   dot(hash22(pi + vec2(1.0, 1.0)), pf - vec2(1.0, 1.0)), w.x),
               w.y);
}

void main(void)
{
    vec2 uv = (vec2(gl_FragCoord.xy.x, gl_FragCoord.xy.y) / min(resolution.x, resolution.y));
    vec2 mouseUv = (vec2(mouse.x*resolution.xy.x, mouse.y*resolution.xy.y) / min(resolution.x, resolution.y));
    
    if(mouseUv.x < 1e-4 && mouseUv.y < 1e-4)
    {
        mouseUv = vec2(resolution.x / resolution.y * 0.5,0.5);
    }
    
    vec2 divisionUv = uv;
    uv = uv * (6.0);
    float result = 0.0;
    if(divisionUv.x < mouseUv.x && divisionUv.y > mouseUv.y)
    {
        result = perlin_noise(uv);
        
        result = result * 0.5 + 0.5;
    }
    else if(divisionUv.x < mouseUv.x && divisionUv.y < mouseUv.y)
    {
        result += 4.0 / 7.0 * perlin_noise(uv);        uv *= 2.0;
        result += 2.0 / 7.0 * perlin_noise(uv);        uv *= 2.0;
        result += 1.0 / 7.0 * perlin_noise(uv);        uv *= 2.0;
        
        result = result * 0.5 + 0.5;
    }
    else if(divisionUv.x > mouseUv.x && divisionUv.y < mouseUv.y)
    {
        result += 4.0 / 7.0 * abs(perlin_noise(uv));        uv *= 2.0;
        result += 2.0 / 7.0 * abs(perlin_noise(uv));        uv *= 2.0;
        result += 1.0 / 7.0 * abs(perlin_noise(uv));        uv *= 2.0;
    }
    else
    {
        result += 4.0 / 7.0 * abs(perlin_noise(uv));        uv *= 2.0;
        result += 2.0 / 7.0 * abs(perlin_noise(uv));        uv *= 2.0;
        result += 1.0 / 7.0 * abs(perlin_noise(uv));        uv *= 2.0;
        
        result = cos(result + uv.x * 0.1);
    }
    
    glFragColor = vec4(result,result,result,1);
    float divisionLine = (1.0 - abs(mouseUv.x - divisionUv.x) * 400.0)
        * (1.0 - abs(mouseUv.y - divisionUv.y) * 400.0);
    divisionLine = clamp(divisionLine,0.0,1.0);
    glFragColor = mix(vec4(1,1,1,1),glFragColor,divisionLine);
}
