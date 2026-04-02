#version 420

// dashxdr 20151110

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 color = vec3(0.0);
vec3 dir, eye, lookat;
float dist = 9999.0;
vec2 spinu, spinv;
vec3 last_contact, last_ndir, last_udir, last_vdir;
vec3 contact=vec3(0.0), ndir=vec3(0.0);
bool hit = false;

void fixup(float fout, vec3 outdir)
{
    if(fout<0.0) return;
    float fup = sqrt(1.0 - fout*fout);
    last_ndir = fup*last_ndir + fout*normalize(outdir);

}

float rim;
float fout(float r, float rmax)
{
    return (r - (rmax-rim)) / rim;
}

bool yinyang(void)
{
    rim = .05*2.0;
    vec3 center1 = 0.5 * last_udir;
    vec3 center2 = -center1;
    float r = length(last_contact);
    float r_fout = fout(r, 1.0);
    if(r>1.0) return false;
    vec3 v1 = last_contact - center1;
    float d1 = length(v1);
    float d1_fout = fout(d1, .5);
    vec3 v2 = last_contact - center2;
    float d2 = length(v2);
    float d2_fout = fout(d2, .5);
    float smallr = 0.15;
    if(d1<smallr + rim)
    {
        if(d1<smallr) return false;
        d1_fout = fout(d1, smallr+rim);
        fixup(1.0 - d1_fout, -v1);
        return true;
    }
    if(d1<0.5 && dot(v1, last_vdir)<0.0)
    {
        fixup(d1_fout, v1);
        return true;
    }
    if(d2<smallr)
    {
        fixup(fout(d2, smallr), v2);
        return true;
    }
    if(d2<0.5) return false;
    if(dot(last_contact, last_vdir)>0.0)
    {
        if(r_fout >= 0.0)
            fixup(r_fout, last_contact);
        else
        {
            d2_fout -= 1.0;
            if(d2_fout >= 0.0 && d2_fout < 1.0)
                fixup(1.0 - d2_fout, -v2);
        }
        return true;
    }
    return false;
}

float lastd;
void yinyangplane(vec3 tracecolor, float h, bool flip)
{
    float m;
    vec3 temp_udir, temp_vdir;
    if(!flip) // xy plane, red
    {
        m = (eye.z - h) / -dir.z;
        last_ndir = vec3(0.0, 0.0, 1.0);
        temp_udir = vec3(1.0, 0.0, 0.0);
        temp_vdir = vec3(0.0, 1.0, 0.0);
    } else // xz plane, blue
    {
        m = (eye.y - h) / -dir.y;
        last_ndir = vec3(0.0, 1.0, 0.0);
        temp_udir = vec3(-1.0, 0.0, 0.0);
        temp_vdir = vec3(0.0, 0.0, -1.0);
    }
    last_contact = eye + m*dir;
    last_udir = spinu.x * temp_udir + spinu.y * temp_vdir;
    last_vdir = spinv.x * temp_udir + spinv.y * temp_vdir;
    lastd = length(eye - last_contact);

    if(yinyang() && lastd<dist)
    {
        dist = lastd;
        color = tracecolor;
        ndir = last_ndir;
        contact = last_contact;
        hit = true;
    }
}

void main()
{
vec2  surfacePos = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;
    vec2 pos = surfacePos * 2.0;

    float tt = time*3.1;
//tt *= .25;
//tt = 3.5;
//tt = 1.5;
tt *= 0.5;

    vec2 rot;
    float downa;

    float zoom = 2.0;

    eye = zoom*vec3(0.5, 1.0, 1.0);
    vec2 m = vec2(0.1, 0.1);
    m *= 3.1415927*2.0;
    float lon = m.x;
    float lat = m.y;
    eye = vec3(sin(lon), 0.0, cos(lon));
    eye = eye*cos(lat) + sin(lat)*vec3(0.0, 1.0, 0.0);
    eye *= zoom;
    lookat = vec3(0.0);

    spinu.x = cos(tt);
    spinu.y = -sin(tt);
    spinv.x = -spinu.y;
    spinv.y = spinu.x;

    vec3 upDirection = vec3(0.0, 1.0, 0.0);
    vec3 cameraDir = normalize(lookat - eye);
    vec3 cameraRight = normalize(cross(cameraDir, upDirection));
    vec3 cameraUp = cross(cameraRight,cameraDir);
    dir = normalize(cameraRight * pos.x + cameraUp * pos.y + 1.5 * cameraDir);

    yinyangplane(vec3(1.0, 0.0, 0.0), 0.0, false); // red
    yinyangplane(vec3(0.0, 0.0, 1.0), 0.0, true); // blue

    vec3 lightpos = .2*vec3(-1.0, 1.0, 2.0);
    if(hit)
    {
        vec3 toeye = normalize(eye - contact);
        vec3 tolight = normalize(lightpos - contact);
        vec3 mid = normalize(toeye + tolight);
        float spectral = pow(max(0.0, dot(mid, ndir)), 32.0);
        color *= min(1.0, dot(tolight, ndir) + .3);
        color += vec3(spectral);
    }

    /*
    if(true) // show light
    {
        vec3 ltoe = lightpos - eye;
        float along = dot(ltoe, dir);
        vec3 closestpoint = eye + along * dir;
        float size = .025*1.0;
        float r = length(closestpoint-lightpos);
        if(r < size)
        {
            float back = sqrt(size*size-r*r);
            closestpoint -= back*dir;
            vec3 rad = closestpoint - lightpos;
                color = vec3(dot(-dir, normalize(rad)));
        }
    }
    */

    glFragColor =  vec4(color, 1.0);
}
