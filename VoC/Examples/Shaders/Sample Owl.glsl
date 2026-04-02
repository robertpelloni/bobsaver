#version 420

// original https://www.shadertoy.com/view/mdtcR4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Eperimenting with 2d drawing in shaders

// Long live the OWL!!

// misol101 2023

const float PI = 3.1416;
const float flyMod = 25.9;

void eye(inout vec3 col, vec2 uv, bool isLeft, vec2 move, float pupilSize) {
    vec2 eyePos = vec2(0.21 * (isLeft? 1. : -1.), 0.22);
    vec3 eyeCol = vec3(0.99, 0.54, 0.03);
    const float eyeSize = 0.15;

    float centDist = length(uv - eyePos);
    eyeCol *= 1. - smoothstep(eyeSize-0.02, eyeSize-0.015, centDist); // black outline
    eyeCol = mix(col, eyeCol, 1. - smoothstep(eyeSize-0.006, eyeSize, centDist)); // AA
    float centDistP = length(uv+move - eyePos);
    eyeCol *= smoothstep(eyeSize*(pupilSize-0.03), eyeSize*pupilSize, centDistP); // pupil

    // Twinkles
    const float HLSize = 0.04, HLSize2 = 0.028;
    vec2 eyeHLPos = eyePos + vec2(-0.045, 0.045) - move * 0.8;
    vec2 eyeHLPos2 = eyeHLPos + vec2(-0.029, 0.029);

    float HLDist = length(uv - eyeHLPos); // big twinkle
    if (HLDist < HLSize)
        eyeCol = mix(eyeCol, vec3(1.), 1. - smoothstep(HLSize-0.02, HLSize-0.016, HLDist));

    HLDist = length(uv - eyeHLPos2);     // small twinkle
    if (HLDist < HLSize2)
        eyeCol = mix(eyeCol, vec3(1.), 1. - smoothstep(HLSize2-0.02, HLSize2-0.016, HLDist));

    col = (centDist < eyeSize) ? eyeCol : col;
}

void lid(inout vec3 col, vec2 uv, bool isLeft, float progress) {
    vec2 lidPos = vec2(0.21 * (isLeft? 1. : -1.), 0.18);
    vec3 lidCol = vec3(0.73, 0.44, 0.33)*2.5;
    const vec2 lidSize = vec2(0.15, 0.2);

    vec2 centDist = abs(uv - lidPos);
    col = (centDist.x < lidSize.x && centDist.y > lidSize.y*progress && centDist.y < lidSize.y) ? lidCol : col;
}

void brow(inout vec3 col, vec2 uv, bool isLeft, float frown) {
    vec2 browPos = vec2(0.21 * (isLeft? 1. : -1.), 0.315);
    vec3 browCol = vec3(0., 0., 0.);
    const float browSize = 0.18;
    uv.y += abs(uv.x-browPos.x)*frown;

    float ydist = (uv.y - browPos.y)*1.5;
    float centDist = length(vec2(uv.x - browPos.x, ydist ));
    browCol *= 1. - smoothstep(browSize-0.035, browSize-0.015, centDist);
    browCol = mix(col, browCol, 1. - smoothstep(browSize-0.009, browSize, centDist)); // AA*3
    browCol = mix(col, browCol, 1.-smoothstep(browSize-0.026, browSize-0.035, centDist));
    browCol = mix(col, browCol, smoothstep(0.11, 0.115, ydist));

    col = (centDist < browSize && centDist > browSize - 0.035 && ydist > 0.09) ? browCol : col;
}

void beak(inout vec3 col, vec2 uv) {
    vec2 beakPos = vec2(0.0, 0.04);
    float beakW = 0.068;
    vec3 beakCol = vec3(0.97, 0.67, 0.12);

    float beakHLw = -0.0015;

    float beakHLx = (uv.x - beakPos.x);
    float tlt = beakHLw + 0.004 + (beakPos.y -uv.y)*0.3;
    if (beakHLx < beakHLw && beakHLx > tlt)
        beakCol = mix(beakCol, vec3(1.), max(0.,1.0-beakHLw/(tlt*0.3)*1.));

    float beakLW = abs(uv.x - beakPos.x) / beakW;

    float breakPosY = beakPos.y + 0.065;
    beakW -= max(uv.y, 0.1) - breakPosY;
    if (uv.y < breakPosY)
        beakW -= 0.35 * (breakPosY - uv.y);
    
    float beakX = abs(uv.x - beakPos.x) / beakW;

    float rel = beakX/beakLW;
    beakCol *= 1. - smoothstep(1.-0.39*rel, 1.-0.3*rel, beakX); // outline
    beakCol = mix(col, beakCol, 1. - smoothstep(1.-0.1*rel, 1.-0.05*rel, beakX)); // AA

    col = (beakX < 1.0) ? beakCol : col;
}

void face(inout vec3 col, vec2 uv, bool isLeft, vec3 faceCol, float faceSize, bool outline, float faceY) {
    float sideMul = isLeft? 1. : -1.;
    vec2 facePos = vec2(0.21 * sideMul, faceY);

    float centDist = length(uv - facePos);

    if (uv.y > facePos.y) {
        float ls = (uv.x*sideMul + facePos.x*(sideMul*-1.) - faceSize) * 0.27;
        faceSize -= ls * (uv.y - facePos.y)*2.;
    }

    if (outline)
        faceCol *= 1. - smoothstep(faceSize-0.02, faceSize-0.015, centDist); // outline
    faceCol = mix(col, faceCol, 1. - smoothstep(faceSize-0.006, faceSize, centDist)); // AA

    col = (centDist < faceSize && uv.x * sideMul > 0.) ? faceCol : col;
}

void body(inout vec3 col, vec2 uv, bool isLeft, vec3 bodyCol, float bodySize, bool outline, float stretchMul) {
    float sideMul = isLeft? 1. : -1.;
    vec2 bodyPos = vec2(0.21 * sideMul, -0.09);

    float centDist = length(uv - bodyPos);

    float ls = (uv.x*sideMul + bodyPos.x*(sideMul*-1.) - bodySize) * 0.23;
    bodySize -= ls * abs(uv.y - bodyPos.y)*stretchMul;

    if (outline)
        bodyCol *= 1. - smoothstep(bodySize-0.02, bodySize-0.015, centDist); // outline
    bodyCol = mix(col, bodyCol, 1. - smoothstep(bodySize-0.006, bodySize, centDist)); // AA

    col = (centDist < bodySize && uv.x * sideMul > 0.) ? bodyCol : col;
}

void claw(inout vec3 col, vec2 uv, vec2 clawPos, float clawSize, float clawH, vec3 clawCol, float tilt, bool isLeft, bool outline) {
    float sideMul = isLeft? 1. : -1.;
    clawPos.x *= sideMul;

    uv.x += (uv.y-clawPos.y) * tilt;
    float centDist = length(vec2((uv.x - clawPos.x)*clawH, uv.y - clawPos.y));
    
    if (outline)
        clawCol *= 1. - smoothstep(clawSize-0.025, clawSize-0.02, centDist); // outline
    clawCol = mix(col, clawCol, 1. - smoothstep(clawSize-0.006, clawSize, centDist)); // AA

    col = (centDist < clawSize && uv.x * sideMul > 0.) ? clawCol : col;
}

void wing(inout vec3 col, vec2 uv, vec2 wingPos, float wingSize, float wingH, vec3 wingCol, float tilt, bool isLeft, bool outline, float rot) {
    float sideMul = isLeft? 1. : -1.; 
    wingPos.x *= sideMul;

    uv.x += (uv.y-wingPos.y) * tilt;
    float centDist = length(vec2((uv.x - wingPos.x)*wingH + 0.07*cos( rot+atan(uv.y,uv.x*sideMul)*25.), uv.y - wingPos.y));

    if (outline)
        wingCol *= 1. - smoothstep(wingSize-0.03, wingSize-0.025, centDist); // outline
    wingCol = mix(col, wingCol, 1. - smoothstep(wingSize-6./resolution.y, wingSize, centDist)); // AA

    col = (centDist < wingSize && uv.x * sideMul > 0.) ? wingCol : col;
}

// from https://www.shadertoy.com/view/lsKSWR by Ippokratis
float vignette(vec2 FC, float extent, float intensity) {
    vec2 uv = FC.xy / resolution.xy;
    uv *=  1.0 - uv.yx;
    float vig = uv.x*uv.y * intensity;
    return pow(vig, extent);
}

// from https://www.shadertoy.com/view/XsfGRn by iq
void heart(inout vec3 col, vec2 uv, vec2 hpos, float scale, vec3 hcol, bool anim, float time) {
    vec2 p = (uv - hpos) / scale;
    
    if (anim) {
        float tt = mod(time,1.5)/1.5;
        float ss = pow(tt,.2)*0.5 + 0.5;
        ss = 1.0 + ss*0.5*sin(tt*6.2831*3.0 + p.y*0.5)*exp(-tt*4.0);
        p *= vec2(0.5,1.5) + ss*vec2(0.5,-0.5);
    }

    float a = atan(p.x,p.y)/3.141593;
    float r = length(p);
    float h = abs(a);
    float d = (13.0*h - 22.0*h*h + 10.0*h*h*h)/(6.0-5.0*h);
    
    col = mix( col, hcol, max(0.,smoothstep( -0.02, 0.02, d-r+0.15) -0.4 ));
}

float hash1(float n) {
    return fract(sin(n)*138.5453123);
}

void animSingle(inout float result, float time, float startTime, float endTime, bool neg) {
    if (time > startTime && time < endTime) {
        result = (neg ? -1. : 1.) * (time-startTime) / (endTime-startTime); 
    }
}

void animate(float speed, out float eyeMove, out float browMove, out float headMove, out float clawMove, out float clawMove2, out float pupilSize, out float pupilSize2, out float blinkL, out float blinkR, out float flyMove) {
    float iT = time * speed;
    float time = mod(iT, 14.);

    animSingle(eyeMove, time, 0.3, 4.3, false);
    animSingle(eyeMove, time, 10.3, 13.3, true);

    animSingle(browMove, time, 1.3, 4.3, false);
    animSingle(browMove, time, 6.3, 8.3, true);

    animSingle(headMove, time, 1.3, 6.3, false);
    animSingle(headMove, time, 9.3, 10.8, true);

    float ctime = mod(iT, 12.);
    animSingle(clawMove, ctime, 1.3, 2.7, true);
    animSingle(clawMove2, ctime, 6.3, 7.4, true);

    float ptime = mod(iT, 32.); 
    animSingle(pupilSize, ptime, 20.3, 25.4, true);
    animSingle(pupilSize2, ptime, 5.2, 8.2, true);
    
    float btime = mod(iT, 15.);
    float blink = 0.4 * speed;
    if ((int(floor(iT / 15.)) % 4) == 2)
        animSingle(blinkL, btime, 4.3, 4.3+blink, true);
    animSingle(blinkL, btime, 14.3, 14.3+blink, true);
    animSingle(blinkR, btime, 14.3, 14.3+blink, true);

    float ftime = mod(iT, flyMod); 
    animSingle(flyMove, ftime, flyMod-14., flyMod-0.1, false);
}

void main(void) {
    vec2 FC = gl_FragCoord.xy;
    // don't ask... :)
    vec2 uv = (FC*1.35)/resolution.y - 0.67;
    uv.y += 0.03;
    uv.x += (1. - resolution.x/resolution.y) * 0.67;

    vec3 col = mix( vec3(1.0,0.8,0.3), vec3(0.58, 0.99, 0.99), sqrt(uv.y+0.67) );

    // hearts
    const vec3 hcol = vec3(0.3,0.8,0.7);
    for (float j = 0.; j < 6.; j++) {
        vec2 hpos = vec2(-0.9 + mod((j-1.) * 0.9,2.4) + sin(time+0.4*j)*0.1, 1.0 - mod(hash1(j)*1.5 + time*(0.3+hash1(j)*0.3), 1.8));
        if (length(hpos-uv) < 0.4)
            heart(col, uv, hpos, 0.2 + hash1(j)*0.1, hcol, true, time + .7*j);
    }
    vec3 bgcol = col;
    
    // entrance on start
    //uv/=0.5 + min(0.5, smoothstep(0.0, 2.0, time) ); uv.y += sin(-PI*0.5-max(0.,1.-time/1.)*(PI-0.5)) * ((max(0.,1.-time))*2.8);
    
    // animate
    float speed = 1., em = 0., bm=0., hm=0., cm=0., cm2=0., ps=0., ps2=0., bL=0., bR=0., fm=0.;
    //if (mouse*resolution.xy.z > 0.) {
        speed = 3.0;
    //}
    animate(speed, em, bm, hm, cm, cm2, ps, ps2, bL, bR, fm);

    float fmS = pow(smoothstep(0.,1.,fm), 0.9);
    if ((int(time/flyMod)-1) % 3 == 0)
        uv *= 1. - sin(time * 1.5) * (sin(fm*PI*2.) * 0.22); // scale while flying
    uv.x += sin(PI * 6. * fmS) * 0.2 * (mod(floor(time*speed / flyMod)+1.,2.)*2.-1.); // flying x
    uv.y += sin(time * 1.5) * (0.005 + sin(fmS*PI) * 0.02); // flying y

    float tilt = 0.15;
    if (uv.y < 0.15 && abs(uv.x) < 0.8) {
        // wings
        vec3 wingCol = vec3(0.73, 0.44, 0.031);
        vec2 wingPos = vec2(0.41, -0.16);
        float flyMove = PI * 2. * fmS * 12.;
        wing(col, uv, wingPos, 0.3, 0.95, wingCol, tilt, true, true, 1.93+sin(time*speed + flyMove));
        wing(col, uv, wingPos, 0.3, 0.95, wingCol, -tilt, false, true, -1.23+sin(time*speed*0.9 + flyMove));
        //bgcol = col; // don't shadow wings

        // body
        vec3 bodyCol = vec3(0.73, 0.44, 0.03);
        body(col, uv, false, bodyCol, 0.34, true, 2.);
        body(col, uv, true, bodyCol, 0.34, true, 2.);

        bodyCol = vec3(0.73, 0.44, 0.33)*2.5;
        body(col, uv, false, bodyCol, 0.24, false, 4.);
        body(col, uv, true, bodyCol, 0.24, false, 4.);
    }

    if (uv.y > -0.25 && abs(uv.x) < 0.6) {
        float headMove = sin(hm * PI * 1.2)*0.2*(1.-abs(hm)) * abs(hm);
        uv.x += headMove;

        // face shadow
        vec3 faceShCol = vec3(0., 0., 0.0), coltemp=col;
        float faceY = 0.125;
        face(coltemp, uv, false, faceShCol, 0.34, false, faceY);
        face(coltemp, uv, true, faceShCol, 0.34, false, faceY);
        if (col != bgcol)
            col = mix(col, coltemp, 0.33);

        // face
        faceY = 0.2;
        vec3 faceCol = vec3(0.73, 0.44, 0.03);
        face(col, uv, false, faceCol, 0.34, true, faceY);
        face(col, uv, true, faceCol, 0.34, true, faceY);

        faceCol = vec3(0.73, 0.44, 0.33)*2.5;
        face(col, uv, false, faceCol, 0.268, false, faceY);
        face(col, uv, true, faceCol, 0.268, false, faceY);

        // eyes
        float pupilSize = 0.7 + max(-1.559,sin(ps*PI*1.)*0.65) + max(-0.11,sin(ps2*PI*1.)*0.15);
        vec2 eyeMove = vec2( max(-0.159,sin(em*PI*1.)*0.04), sin(em*PI)*0.011);
        eye(col, uv, false, eyeMove, pupilSize);
        eye(col, uv, true, eyeMove, pupilSize);

        lid(col, uv, true, cos(bL*PI*2.)*0.5+0.5);
        lid(col, uv, false, cos(bR*PI*2.)*0.5+0.5);

        beak(col, uv);

        // brows
        float browMove = -sin(bm*PI*1.)*0.3;
        brow(col, uv, false, browMove);
        brow(col, uv, true, browMove);

        uv.x -= headMove;
    }

    // claws
    vec3 clawCol = vec3(1., 0.54, 0.03);
    vec2 clawPos = vec2(0.21, -0.495);
    tilt = 0.25;
    
    if(abs(clawPos.y-uv.y) < 0.1 && abs(uv.x) < 0.25) {
        vec2 clawMove = vec2( sin(cm * PI * 1.1)*0.15*(1.-abs(cm)) * abs(cm), sin(cm*PI)*0.005);
        vec2 clawMove2 = vec2( sin(cm2*PI)*0.005, sin(cm2 * PI * 1.5)*0.15*(1.-abs(cm2)) * abs(cm2));
        for (float i = 0.; i<3.; i++) {
            claw(col, uv+clawMove*(i+0.2)*0.25, clawPos, 0.07, 1.75, clawCol*0.7, tilt, true, true);
            claw(col, uv+clawMove*(i+0.2)*0.25, clawPos+vec2(0.,0.008), 0.045, 1.75, clawCol, tilt, true, false);

            claw(col, uv+clawMove2*(0.15+i*0.2)*1.35, clawPos, 0.07, 1.75, clawCol*0.7, -tilt, false, true);
            claw(col, uv+clawMove2*(0.15+i*0.2)*1.35, clawPos+vec2(0.,0.008), 0.045, 1.75, clawCol, -tilt, false, false);
            clawPos += vec2(-0.06, -0.01);
            tilt -= 0.09;
        }
    }

    // post processing
    float vig = 1.;
    vig = vignette(FC, 0.08, 75.0);

    glFragColor = vec4(col*vig,1.0);
}