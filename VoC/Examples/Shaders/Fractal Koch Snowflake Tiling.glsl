#version 420

// original https://www.shadertoy.com/view/7dKfz1

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 norm(vec2 p0, vec2 p1, vec2 p) {
    float a = p.x - p0.x;
    float b = p.y - p0.y;
    float c = p1.x - p0.x;
    float d = p1.y - p0.y;
    float x = (a*c+b*d)/(c*c+d*d);
    float y = (b*c-a*d)/(c*c+d*d);
    return vec2(x,y);
}

vec2 rotate(vec2 p, vec2 center, float angle) {
    float x = p.x - center.x;
    float y = p.y - center.y;
    float s = sin(angle);
    float c = cos(angle);
    float rx = c*x - s*y;
    float ry = s*x + c*y;
    return center + vec2(rx,ry);
}

const float pi = 3.1415926;
float ease(float x) {
    return (1.0 - cos(pi * x)) / 2.0;
}

bool inTriangle(vec2 pt) {
    float x = pt.x;
    float y = pt.y;
    if (y < 0.0 || y > x/sqrt(3.0) || y > -(x-1.0)/sqrt(3.0))
        return false;
    
    bool b = true;
    while (true) {
        if (y > sqrt(3.0)*(x - 1.0/3.0)) {
            float tx = 1.5*x + sqrt(3.0)/2.0*y;
            float ty = sqrt(3.0)/2.0*x - 1.5*y;
            x = tx;
            y = ty;
            b = !b;
        } else if (y > -sqrt(3.0)*(x - 2.0/3.0)) {
            float tx = 1.5*(1.0-x) + sqrt(3.0)/2.0*y;
            float ty = sqrt(3.0)/2.0*(1.0-x) - 1.5*y;
            x = tx;
            y = ty;
            b = !b;
        } else {
            return b;
        }
    }
}

bool inFractal(vec2 coord, vec2 center, float radius) {
    float x = coord.x - center.x;
    float y = coord.y - center.y;
    vec2 pt = vec2(x,y);
    
    float s = radius / 2.0;
    vec2 verts[3] = vec2[3](
        vec2(-sqrt(3.0)*s, s),
        vec2(sqrt(3.0)*s, s),
        vec2(0, -2.0*s)
    );
    
    if (y > s) {
        pt = norm(verts[0], verts[1], pt);
    } else if (y < sqrt(3.0)*x - 2.0*s) {
        pt = norm(verts[1], verts[2], pt);
    } else if (y < -sqrt(3.0)*x - 2.0*s) {
        pt = norm(verts[2], verts[0], pt);
    } else {
        return true;
    }
    return inTriangle(pt);
}

const float bR = 100.0;
const float bH = bR;
const float bW = bR * sqrt(3.0);
const vec2 shift = vec2(0,90);
vec2 possibleBlack(vec2 coord) {
    vec2 v = coord + shift;
    float x = mod(v.x, 2.0 * bW) - bW;
    float y = mod(v.y, 2.0 * bH) - bH;
    if (x*x + y*y <= bR*bR) {
        return coord - vec2(x,y);
    } else {
        x = mod(v.x + bW, 2.0 * bW) - bW;
        y = mod(v.y + bH, 2.0 * bH) - bH;
        if (x*x + y*y <= bR*bR) {
            return coord - vec2(x,y);
        } else {
            return vec2(-100);
        }
    }
}

const float wR = bR / sqrt(3.0);
const float wH = wR * sqrt(3.0);
const float wW = wR;
vec2 possibleWhite(vec2 coord) {
    vec2 v = coord + vec2(bW,bH) + shift;
    float x = mod(v.x, 2.0 * wW) - wW;
    float y = mod(v.y, 2.0 * wH) - wH;
    if (x*x + y*y <= wR*wR) {
        return coord - vec2(x,y);
    } else {
        x = mod(v.x + wW, 2.0 * wW) - wW;
        y = mod(v.y + wH, 2.0 * wH) - wH;
        if (x*x + y*y <= wR*wR) {
            return coord - vec2(x,y);
        } else {
            return vec2(-100);
        }
    }
}

const float spinTime = 90.0;
const float pauseTime = 30.0;
const float period = 2.0*(spinTime + pauseTime);
bool inWhite(vec2 coord) {
    float frame = mod(float(frames), period);
    vec2 blackCenter = possibleBlack(coord);
    vec2 whiteCenter = possibleWhite(coord);
    bool possibleB = (blackCenter.x > -10.0);
    bool possibleW = (whiteCenter.x > -10.0);
    
    if (distance(coord, blackCenter) < wR) {
        return false;
    }
    if (frame < spinTime) { // black spinning
        if (possibleB) {
            float angle = -60.0 * ease(frame / spinTime);
            vec2 c = rotate(coord, blackCenter, radians(angle));
            return !inFractal(c, blackCenter, bR);
        }
        return true;
    } else {
        if (possibleW) {
            float angle = 30.0;
            frame -= spinTime + pauseTime;
            if (0.0 < frame && frame < spinTime) // white spinning
                angle += 60.0 * ease(frame / spinTime);
            vec2 c = rotate(coord, whiteCenter, radians(angle));
            return inFractal(c, whiteCenter, wR);
        }
        return false;
    }
}

const int s = 3;
void main(void)
{
    float white = 0.0;
    for (int i = 0; i < s; i++) {
        for (int j = 0; j < s; j++) {
            vec2 coord = gl_FragCoord.xy + vec2(i,j)/float(s);
            white += float(inWhite(coord));
        }
    }
    
    vec3 col = vec3(white / float(s*s));
    
    glFragColor = vec4(col,0.0);
}
