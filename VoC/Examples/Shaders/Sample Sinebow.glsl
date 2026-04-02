#version 420

// original https://neort.io/art/bqtbpas3p9f48fkit5eg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

void main(void) {
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    
    float pi = 3.14159265;
    
    //スクロール用
    float rtime = time + uv.x * 2.;
    
    
    //普通の虹の描画
    float rp = (pi / 3.) * .5;
    float halfpi = pi /2.;
        
    float R = clamp(acos(cos(rtime + halfpi)) - halfpi, -rp, rp) + rp;
    float G = clamp(acos(cos(rtime + halfpi - pi/3. * 2.)) - halfpi, -rp, rp) + rp;
    float B = clamp(acos(cos(rtime + halfpi - pi/3. * 4.)) - halfpi, -rp, rp) + rp;
    
    //グラデーション変化用
    float tG = clamp(acos(cos(rtime + halfpi - pi/3. * 2. * time)) - halfpi, -rp, rp) + rp;
    float mixTime = 0.5 * time;
    G = mix(G, tG, clamp(acos(cos(mixTime + halfpi)) - halfpi, -rp, rp) + rp);
    
    vec3 rainbow = vec3(R, G, B);
    
    //普通の虹のグラフ
    vec2 guv = uv;
    guv.y -= .58; //上下位置
    float waveR = 0.005 / abs(-guv.y + R *0.3);
    float waveG = 0.005 / abs(-guv.y + G *0.3);
    float waveB = 0.005 / abs(-guv.y + B *0.3);
    vec3 wave = vec3(waveR, waveG, waveB);
    
    //sinebowの描画
    float sR = (sin(rtime) +1.) * 0.5;
    float sG = (sin(rtime - pi/3. * 2.) + 1.) * 0.5;
    float sB = (sin(rtime - pi/3. * 4.) + 1.) * 0.5;
    
    //グラデーション時間で切り替え用
    float tsG = (sin(rtime - pi/3. * 2. * time) + 1.) * 0.5;
    sG = mix(sG, tsG, clamp(acos(cos(mixTime + halfpi)) - halfpi, -rp, rp) + rp);
    
    vec3 sinebow = vec3(sR, sG, sB);
    
    //sinebowのグラフ
    vec2 sguv = uv;
    sguv.y += .87; //上下位置
    float swaveR = 0.005 / abs(-sguv.y + sR *0.3);
    float swaveG = 0.005 / abs(-sguv.y + sG *0.3);
    float swaveB = 0.005 / abs(-sguv.y + sB *0.3);
    vec3 swave = vec3(swaveR, swaveG, swaveB);
    
    //分割用
    float divide0 = step(0.5, uv.y);
    float divide1 = (1. - step(.5, uv.y)) * step(0., uv.y);
    float divide2 = (1. - step(0., uv.y)) * step(-.5, uv.y);
    float divide3 =  1.-step(-.5, uv.y);

    //mix
    vec3 col = wave * divide0 +rainbow * divide1 + sinebow * divide2 + swave * divide3;

    glFragColor = vec4(col, 1.0);
}
