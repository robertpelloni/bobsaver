#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/ftsGz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Per Bloksgaard/2021
// Raytracing a strange antigravity jellyfish.
const float PI = 3.14159;

vec4 QuatFromAxisAngle(vec3 axis, float angle)
{
    float hA = angle * 0.5;
    float s = sin(hA);
    float c = cos(hA);
    return vec4(axis*s, c);
}

vec4 QuatMul(vec4 q, vec4 r)
{
    vec4 nq;
    nq.x = q.w * r.x + q.x * r.w + q.y * r.z - q.z * r.y;
    nq.y = q.w * r.y - q.x * r.z + q.y * r.w + q.z * r.x;
    nq.z = q.w * r.z + q.z * r.w - q.y * r.x + q.x * r.y;
    nq.w = q.w * r.w - q.x * r.x - q.y * r.y - q.z * r.z;
    return nq;
}

mat4 QuatToMat(vec4 q)
{
    float xx = q.x * q.x, yy = q.y * q.y, zz = q.z * q.z;
    float xy = q.x * q.y, yz = q.y * q.z, xz = q.x * q.z;
    float xw = q.x * q.w, yw = q.y * q.w, zw = q.z * q.w;
    return mat4(1.-2.*(yy+zz),2.*(xy-zw),2.*(xz+yw),0.,2.*(xy+zw),1.-2.*(xx+zz),2.*(yz-xw),0.,2.*(xz-yw),2.*(yz+xw),1.-2.*(xx+yy),0.,0.,0.,0.,1.);
}

mat3 QuatToMat3(vec4 q)
{
    float xx = q.x * q.x, yy = q.y * q.y, zz = q.z * q.z;
    float xy = q.x * q.y, yz = q.y * q.z, xz = q.x * q.z;
    float xw = q.x * q.w, yw = q.y * q.w, zw = q.z * q.w;
    return mat3(1.-2.*(yy+zz),2.*(xy-zw),2.*(xz+yw),2.*(xy+zw),1.-2.*(xx+zz),2.*(yz-xw),2.*(xz-yw),2.*(yz+xw),1.-2.*(xx+yy));
}

mat4 createObjectRotationMatrix(float fAzimuth, float fZenith, float fRoll)
{
    vec4 u = QuatFromAxisAngle(vec3(0., 1., 0.), -fAzimuth);
    vec4 v = QuatFromAxisAngle(QuatToMat3(u) * vec3(1., 0., 0.), fZenith);
    v = QuatMul(v,u);
    vec4 w = QuatFromAxisAngle(QuatToMat3(v) * vec3(0., 0., 1.), -fRoll);
    return QuatToMat(QuatMul(w,v));
}

mat3 createCameraRotationMatrix(float fU, float fV)
{
    vec4 u = QuatFromAxisAngle(vec3(0., 1., 0.), -fU);
    vec4 v = QuatFromAxisAngle(QuatToMat3(u) * vec3(1., 0., 0.), fV);
    return QuatToMat3(QuatMul(u,v));
}

mat4 translate(vec3 v)
{
    return mat4(1., 0., 0., 0., 0., 1., 0., 0., 0., 0., 1., 0., v.x, v.y, v.z, 1.);
}

float derivative(vec2 p)
{
    vec2 dx = dFdx(p);
    vec2 dy = dFdy(p);
    vec2 d = p - floor(p);
    return exp2(-0.31 * min((1. - d.x) * d.x, (1. - d.y) * d.y) / (dot(dx, dy) + dot(dy, dy) + 8e-4));
}

float floorGrid(vec2 p, float od)
{
    vec2 d = p - floor(p);
    return exp2(-0.23 * min((1. - d.x) * d.x, (1. - d.y) * d.y) / clamp(od * -1e-3 + od * od *25e-5,3e-3,1e4));
}

float waveSin(float x, float t)
{
    float scalar = sin(x * PI / 8.);
    float y = sin((x + t * 0.5 * 0.5) * -1.3) * 2.38;
    y += sin((x + t * -0.15 * 0.5) * -23.89) * 1.41;
    y *= scalar * 0.34;
    y += scalar * 3.3;
    return y;
}

vec3 skyColor(vec3 p)
{
    float u = atan(p.z, p.x) + 0.68;
    p.x = cos(u);
    p.z = abs(sin(u));
    vec3 sunPos = vec3(0., 0.0998, 0.995);
    float h = 0.75 - 0.75 * dot(p, sunPos) * clamp(1. - 3.2*p.y, 0., 1.) * 0.89384734;
    float w = length(sunPos - p) * 20.;
    float fSkylar = clamp(1. - w * w * 73e-5, 0., 1.);
    vec3 vA = mix(vec3(0.894111, 0.517647, 0.109803), vec3(0.658823, 0.545098, 0.325490) * fSkylar, 4. * (h * 2. - 0.25)) * 0.75;
    vec3 vB = vec3(0.25 + 0.278285 * (dot(p, sunPos) + 1.));
    vec3 vC = (vA + vB) * 0.5;
    float l = w * 0.048402;
    vec3 z = vec3(1.,2.,3.) * 0.0446 - 0.8;
    vec3 sunColor = vec3(0.0028) / ((pow(vec3(0.5) + l + 1.8611 * (cos(0.5 - z)) * abs(sin(l * 8.9583 - z * 2.)), vec3(1.2)) - vec3(0.5)) * l);
    return max(mix(vC, vC * 0.4 + sunColor, length(sunColor) * 1.5) + sunColor, vec3(0.2,0.25,0.4));
}

vec3 calcSceneColorNonDerivative(in vec3 vCamPos, in vec3 vRayDir)
{
    float d = min(-vCamPos.y / min(vRayDir.y, -1e-6), 1e6);
    if (vRayDir.y > 0.)
    {
        return skyColor(vRayDir);
    }
    else
    {
        vec3 vHitPos = vCamPos + vRayDir * d;
        float vDer = floorGrid(vHitPos.xz, d - acos(vRayDir.y)*d*0.4);
        return clamp(mix(skyColor(vec3(vRayDir.x, -vRayDir.y, vRayDir.z)), vec3(1. - vDer), smoothstep(0., -0.2, vRayDir.y)), 0., 1.);
    }
}

vec3 calcSceneColorDerivative(in vec3 vCamPos, in vec3 vRayDir)
{
    float d = min(-vCamPos.y / min(vRayDir.y, -1e-6), 1e6);
    if (vRayDir.y > 0.)
    {
        return skyColor(vRayDir);
    }
    else
    {
        vec3 vHitPos = vCamPos + vRayDir * d;
        float fD = derivative(vHitPos.xz);
        return clamp(mix(skyColor(vec3(vRayDir.x, -vRayDir.y, vRayDir.z)), vec3(1. - fD), smoothstep(0., -0.2, vRayDir.y)), 0., 1.);
    }
}

float addv(vec2 a)
{
    return a.x + a.y;
}

vec2 findQuadricRoots(vec2 coeffs, float a)
{
    float p = coeffs.y * 0.5;
    float D = p * p - coeffs.x;
    if (D <= 0.)
    {
        return vec2(-1.);
    }
    else
    {
        return vec2(-1, 1) * sqrt(D) - (p + a * 0.25);
    }
}

float findCubicRoot(vec3 a)
{
    float p = a.y - a.x*a.x / 3.;
    float p3 = p*p*p;
    float q = a.x*(2.*a.x*a.x - 9.*a.y) / 27. + a.z;
    float d = q*q + 4.*p3 / 27.;
    float e = -a.x / 3.;
    if (d>.0)
    {
        float z = sqrt(d);
        vec2 x = (vec2(z, -z) - q) * 0.5;
        vec2 uv = sign(x)*pow(abs(x), vec2(1./3.));
        return e + uv.x + uv.y;
    }
    float v = acos(-sqrt(-27. / p3)*q*.5) / 3.;
    return (cos(v)*2.) * sqrt(-p/3.) + e;
}

vec4 findQuarticRoots(vec4 qc)
{
    float aa = qc.x*qc.x;
    float p = -0.375*aa+qc.y;
    float q = 0.125*aa*qc.x-0.5*qc.x*qc.y+qc.z;
    float r = -3./256.*aa*aa+1./16.*aa*qc.y-0.25*qc.x*qc.z+qc.w;
    float z = findCubicRoot(vec3(-0.5*p,-r,0.5*r*p-0.125*q*q));
    float u = z*z-r;
    float v = 2.*z-p;
    if (u > 0.)
    {
        u = sqrt(u);
    }
    else
    {
        return vec4(-1.);
    }
    if (v > 0.)
    {
        v = sqrt(v);
    }
    else
    {
        return vec4(-1.);
    }
    float sQ = sign(q);
    return vec4(findQuadricRoots(vec2(z-u,v*sQ),qc.x),findQuadricRoots(vec2(z+u,v*-sQ),qc.x));
}

float evalQuad(float x, vec3 C)
{
    return C.z + x * (C.y + x * C.x);
}

void findCylinderNearFar(vec3 ro, vec3 rd, float r, vec2 cy, out float fNear, out float fFar)
{
    // x^2 + z^2 = r^2 => (ro.x + t*rd.x)^2 + (ro.z + t*rd.z)^2 = r^2
    float fA = dot(rd.xz, rd.xz);
    float fB = 2. * dot(rd.xz, ro.xz);
    float fC = dot(ro.xz, ro.xz) - r * r;
    float fDet = fB * fB - 4. * fA * fC;
    if (fDet < 0.)
    {
        fNear = 0.;
        fFar = -1.;
        return;
    }
    float sqrtD = sqrt(fDet);
    float inv2A = 1. / (2. * fA);
    vec2 p = (cy - ro.y) / rd.y;
    p += step(rd.y,0.) * (p.yx - p);
    fNear = max((-fB - sqrtD) * inv2A, p.x);
    fFar = min((-fB + sqrtD) * inv2A, p.y);
}

vec4 findQuarticMinDistance(vec3 Q, float offset, float fYDirectionDevisor, float cylinderRadius, vec3 rd, vec3 ro)
{
    rd.y /= fYDirectionDevisor;
    ro.y += fYDirectionDevisor * 0.5;
    ro.y -= offset;
    ro.y /= fYDirectionDevisor;
    float near;
    float far;
    findCylinderNearFar(ro, rd, cylinderRadius + 1e-3, vec2(-1e-3, 1. + 1e-3), near, far);
    if (far < 1e-3 || near > far)
    {
        return vec4(0.,0.,0.,1e5);
    }
    near = max(0., near);
    ro += rd * near;
    // Equation solution here: perbloksgaard.dk/research/RayDistanceToBezierCylinder.jpg
    float A = Q.x * Q.x * rd.y * rd.y * rd.y * rd.y;
    float B = 2. * Q.x * rd.y * rd.y * rd.y * (2. * Q.x * ro.y + Q.y);
    float C = rd.y * rd.y * (6. * Q.x * ro.y * (Q.x * ro.y + Q.y) + 2. * Q.x * Q.z + Q.y * Q.y) - rd.x * rd.x - rd.z * rd.z;
    float D = rd.y * (ro.y * (Q.x * (4. * Q.x * ro.y * ro.y + 6. * Q.y * ro.y + 4. * Q.z) + 2. * Q.y * Q.y) + 2. * Q.y * Q.z) - 2. * (rd.x * ro.x + rd.z * ro.z);
    float E = ro.y * (Q.x * ro.y * (Q.x * ro.y * ro.y + 2. * Q.y * ro.y + 2. * Q.z) + Q.y * (Q.y * ro.y + 2. * Q.z)) + Q.z * Q.z - ro.x * ro.x - ro.z * ro.z;
    vec4 roots = findQuarticRoots(vec4(D, C, B, A) / E);
    float l = 1. / max(roots.x, max(roots.y, max(roots.z, roots.w)));
    if ((l > 1e-3) && l < (far - near))
    {
        vec3 w = ro + rd * l;
        vec3 q = vec3(normalize(w.xz) * (Q.y + Q.x * w.y * 2.), 1.);
        return vec4(vec3(w.x*q.z,-w.x*q.x-w.z*q.y, w.z*q.z), near + l);
    }
    return vec4(0.,0.,0.,1e5);
}

vec3 render(in vec2 uv, float aW[12], float aL[9], float aR[9], float maxGlobalRadius, vec3 vCamPosition, mat3 vCamMat, mat4 txx, mat4 txi)
{
    const int iC = 9;
    const float fFocalLength = 3.732051;
    vec3 totalColorSum = vec3(0.);
    vec2 vScreenPixel = vec2(0.5) / vec2(resolution);
    vec3 backGroundColor = calcSceneColorDerivative(vCamPosition, normalize(uv.x * vCamMat[0] + uv.y * vCamMat[1] + fFocalLength * vCamMat[2]));
    for (int iR = 0; iR < 4; iR++)
    {
        int iX = iR / 2;
        int iY = iR % 2;
        vec3 rd = normalize((uv.x -vScreenPixel.x + vScreenPixel.x * 2. * float(iX)) * vCamMat[0] + (uv.y -vScreenPixel.y + vScreenPixel.y * 2. * float(iY)) * vCamMat[1] + fFocalLength * vCamMat[2]);
        vec3 ro = vCamPosition;
        vec3 lRD = (txi * vec4(rd, 0.)).xyz;
        vec3 lRO = (txi * vec4(ro, 1.)).xyz;
        vec3 colorSum = vec3(0.);
        float near, far;
        findCylinderNearFar(lRO, lRD, maxGlobalRadius + 1e-3, vec2(-1e-3, float(iC) + 1e-3), near, far);
        if (far < 1e-3 || near > far)
        {
            return backGroundColor;
        }
        float nearY = lRO.y + lRD.y * near;
        float farY = lRO.y + lRD.y * far;
        int iVEnd = iC;
        int iA = 0;
        int iANear = 0;
        int iAFar = 0;
        float fOffsetNear = 0.;
        float fOffsetFar = 0.;
        if (nearY > fOffsetNear)
        {
            for (; iANear < 8; iANear++)
            {
                if ((fOffsetNear < nearY) && ((fOffsetNear + aL[iANear]) > nearY))
                {
                    break;
                }
                fOffsetNear += aL[iANear];
            }
        }
        if (farY > fOffsetFar)
        {
            for (; iAFar < 8; iAFar++)
            {
                if ((fOffsetFar < farY) && ((fOffsetFar + aL[iAFar]) > farY))
                {
                    break;
                }
                fOffsetFar += aL[iAFar];
            }
        }
        float fInt = 1.;
        float localReflection = 1.0526315;
        for (int h = 0; h < 4; h++)
        {
            vec4 i = vec4(0., 0., 0., 1e3);
            float fD = sign(float(iAFar - iANear));
            int dL = int(fD);
            int iAIdx = (fD > 0.) ? 0 : iC - 1;
            float fYOffset = (fD > 0.) ? 2e-2 : 2e-2 + float(iC);
            iVEnd = abs(iAFar - iANear) + 1;
            iAIdx = iANear;
            fYOffset = fOffsetNear;
            int iBIdx = iAIdx + 1;
            int iCIdx = iBIdx + 1;
            for (int iV = 0; iV < iVEnd; iV++)
            {
                float a = aW[iAIdx];
                float b = aW[iBIdx];
                float c = aW[iCIdx];
                fYOffset += aL[iAIdx] * 0.5;
                vec4 di = findQuarticMinDistance(vec3(a-2.*b+c,-2.*a+2.*b,a+b), fYOffset, aL[iAIdx], aR[iAIdx], lRD, lRO);
                if (di.w > 1e-4 && di.w < 1e3)
                {
                    i = di;
                    break;
                }
                fYOffset += aL[iAIdx] * 0.5;
                if (dL < 0)
                {
                    fYOffset -= aL[iAIdx];
                }
                iAIdx += dL;
                iBIdx += dL;
                iCIdx += dL;
                if (dL < 0)
                {
                    fYOffset -= aL[iAIdx];
                }
            }
            if (i.w > 1e2)
            {
                if (h == 0)
                {
                    return backGroundColor;
                }
                else
                {
                    colorSum += calcSceneColorNonDerivative(ro, rd) * fInt;
                }
                break;
            }
            vec3 n = (txx * vec4(normalize(i.xyz), 0.)).xyz;
            vec3 posZNormal = faceforward(n, rd, n);
            float refac = mix(0.027, 0.77, clamp(pow(1. - dot(rd, -posZNormal), 2.8), 0., 1.));
            ro += rd * (i.w + 2e-2) - posZNormal * abs(dot(rd, n) * 2e-2);
            vec3 color = clamp(calcSceneColorNonDerivative(ro, reflect(rd, posZNormal)) * refac * fInt, 0., 1.);
            if (h > 0)
            {
                color *= (1. + i.w * 9e-2);
            }
            colorSum += color;
            fInt *= pow(0.36, refac);
            rd = refract(rd, posZNormal, localReflection);
            lRD = (txi * vec4(rd, 0.)).xyz;
            lRO = (txi * vec4(ro, 1.)).xyz;
            localReflection = 1.;
        }
        totalColorSum += mix(colorSum, clamp(colorSum * (vec3(1.) - vec3(0.55, 0.6, 0.65)) + backGroundColor * vec3(0.55, 0.6, 0.65), 0., 1.), step(min(colorSum.x, min(colorSum.y, colorSum.z)), 0.39));
    }
    return totalColorSum * 0.25;
}

void main(void)
{
    float t = time + 126.5;
    float aW[12];
    float aL[9];
    float aR[9];
    aW[1] = (waveSin(0.5, t) + waveSin(1., t))*0.35;
    aW[0] = -aW[1];
    for (int iWIdx = 2; iWIdx < 10; iWIdx++)
    {
        aW[iWIdx] = waveSin(float(iWIdx - 1), t) - aW[iWIdx - 1];
    }
    aW[9] = -aW[8] + aW[7] * 0.5;
    aW[10] = -aW[9];
    aW[11] = 0.0;
    float fSin;
    aL[4] = 1.;
    fSin = sin(t*-1.5 + pow(0.4, 0.3)) * pow(0.4, 0.25);
    aL[3] = 1. + fSin;
    aL[5] = 1. - fSin;
    fSin = sin(t*-1.5 + pow(0.4, 0.3*2.)) * pow(0.4, 0.25*2.);
    aL[2] = 1. + fSin;
    aL[6] = 1. - fSin;
    fSin = sin(t*-1.5 + pow(0.4, 0.3*3.)) * pow(0.4, 0.25*3.);
    aL[1] = 1. + fSin;
    aL[7] = 1. - fSin;
    fSin = sin(t*-1.5 + pow(0.4, 0.3*4.)) * pow(0.4, 0.25*4.);
    aL[0] = 1. + fSin;
    aL[8] = 1. - fSin;
    float maxGlobalRadius = 0.;
    for (int iR = 0; iR < 9; iR++)
    {
        float a = aW[iR];
        float b = aW[iR + 1];
        float c = aW[iR + 2];
        vec3 Q = vec3(a - 2.*b + c, -2.*a + 2.*b, a + b);
        float maxRadius = max(evalQuad(clamp(-Q.y / (2.*Q.x), 0., 1.), Q), max(evalQuad(0., Q), evalQuad(1., Q)));
        maxGlobalRadius = max(maxGlobalRadius, maxRadius);
        aR[iR] = maxRadius;
    }
    mat4 qM = createObjectRotationMatrix(sin(t*1e-2)*1e-2,sin(t*0.37)*0.45-4.67,sin(t*0.25)*0.9+1.1);
    vec3 vObjPos = vec3(cos(0.8)*t*-2.1, 5.63, sin(0.8)*t*-2.1);
    vec3 vObjCenter = vec3(0., 4.5, 0.);
    mat4 txi = translate(vObjCenter) * qM * translate(-vObjPos);
    mat4 txx = inverse(txi);
    mat3 vCamMat = createCameraRotationMatrix(-cos(t*0.11)*0.25+9.87, sin(-t*0.31)*0.16-0.007158);
    mat3 iQM = inverse(mat3(qM));
    vec3 vCamPosition = vObjPos - vCamMat[2] * (17. - cos(t * 0.4) * 7.);
    vCamPosition.xz += iQM[1].xz * (dot(vObjPos - vCamPosition, iQM[1]) / dot(iQM[1], iQM[1])) * 0.6;
    vec2 s = (-1.+2.*gl_FragCoord.xy/resolution.xy)*vec2(resolution.x/resolution.y,1.);
    glFragColor = vec4(render(s, aW, aL, aR, maxGlobalRadius, vCamPosition, vCamMat, txx, txi),1.);
}
