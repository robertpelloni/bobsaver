#version 420

// original https://www.shadertoy.com/view/ttyfW1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float paintregion (float col1, float col2, float colx, float row1, float row2, float rowx) {
    vec2 st = gl_FragCoord.xy/resolution.xy;
    float region = step(min(col1, col2),st.x) * step(st.x, max(col1, col2)); // between col2 and col1
    region *= max(step(colx, col2) * step(colx, col1), step(col2, colx) * step(col1, colx)); // only if both are < or > colx
    region *= step(min(row1, row2),st.y) * step(st.y, max(row1, row2)); // between row2 and row1
    region *= max(step(rowx, row2) * step(rowx, row1), step(row2, rowx) * step(row1, rowx)); // only if both are < or > rowx
    return region;  
}

float paintminicol(float miniwidth, float col1, float col2, float colx, float row1, float row2, float rowx) {
    vec2 st = gl_FragCoord.xy/resolution.xy; 
    float mini = step((col1+col2)/2.0-miniwidth,st.x) * step(st.x, (col1+col2)/2.0+miniwidth); // between col2 and col1
    mini *= max(step(colx, col2) * step(colx, col1), step(col2, colx) * step(col1, colx)); // only if both are < or > colx
    mini *= step(min(row1, row2),st.y) * step(st.y, max(row1, row2)); // between row2 and row1
    mini *= max(step(rowx, row2) * step(rowx, row1), step(row2, rowx) * step(row1, rowx)); // only if both are < or > rowx
    return mini;  
}

float paintminirow(float miniheight, float col1, float col2, float colx, float row1, float row2, float rowx) {
    vec2 st = gl_FragCoord.xy/resolution.xy; 
    float mini = step((row1+row2)/2.0-miniheight,st.y) * step(st.y, (row1+row2)/2.0+miniheight); // between row2 and row1
    mini *= max(step(rowx, row2) * step(rowx, row1), step(row2, rowx) * step(row1, rowx)); // only if both are < or > rowx
    
    
    mini *= step(min(col1, col2),st.x) * step(st.x, max(col1, col2)); // between col2 and col1
    mini *= max(step(colx, col2) * step(colx, col1), step(col2, colx) * step(col1, colx)); // only if both are < or > colx
    return mini;  
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    //vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 st = gl_FragCoord.xy/resolution.xy;
    vec3 color = vec3(0.0);

    float xwide = 0.02;
    float xthin = 0.01;
    float ywide = 0.02;
    float ythin = 0.01;
    
    float spda = 0.06;
    float spdb = 0.09;
    float spdc = -0.07;
    float spdd = 0.1;
    float spde = -0.08;
    float spdf = 0.12;
    
    float cola = mod(0.1+time*spda, 1.2) - 0.1;
    float all = 1.0 - step(cola,st.x) * step(st.x, cola+xwide);
    float colb = mod((0.3+time*spdb), 1.2) - 0.1;
    all *= 1.0 - step(colb,st.x) * step(st.x, colb+xthin);
    float colc = mod((0.5+time*spdc), 1.2) - 0.1;
    all *= 1.0 - step(colc,st.x) * step(st.x, colc+xwide);
    
    float rowd = mod(0.1+time*spdd, 1.2) - 0.1;
    all *= 1.0 - step(rowd,st.y) * step(st.y, rowd+ythin);
    float rowe = mod((0.3+time*spde), 1.2) - 0.1;
    all *= 1.0 - step(rowe,st.y) * step(st.y, rowe+ywide);
    float rowf = mod((0.5+time*spdf), 1.2) - 0.1;
    all *= 1.0 - step(rowf,st.y) * step(st.y, rowf+ywide);
    
    color = vec3(all);
    
    float pred;
    pred = paintregion(colb, colc, cola, rowe, rowf, rowd);         // BC EF
    color *= vec3(1.0-0.1*pred,1.0-0.8*pred, 1.0-0.75*pred);
    pred = paintregion(cola, colb, colc, rowd, rowe, rowf);         // AB DE
    color *= vec3(1.0-0.1*pred,1.0-0.8*pred, 1.0-0.75*pred);
    
    float pblue;
    pblue = paintregion(cola, colc, colb, rowe, rowf, rowd);         // AC EF
    color *= vec3(1.0-0.75*pblue,1.0-0.8*pblue, 1.0-0.1*pblue);
    pblue = paintregion(cola, colb, colc, rowd, rowf, rowe);         // AB DF
    color *= vec3(1.0-0.75*pblue,1.0-0.8*pblue, 1.0-0.1*pblue);
        
    float pyellow;
    pyellow = paintregion(colb, colc, cola, rowd, rowe, rowf);         // BC DE
    color *= vec3(1.0-0.1*pyellow,1.0-0.2*pyellow, 1.0-0.8*pyellow);
    
    float pgrey;
    pgrey = paintregion(cola, colc, colb, rowd, rowf, rowe);         // AC DF
    color *= vec3(1.0-0.3*pgrey,1.0-0.3*pgrey, 1.0-0.3*pgrey);
    
    float mwidth = 0.005; 
    float minicol;
    minicol = paintminicol(mwidth, cola, colc, colb, rowd, rowe, rowf);         // AC DE
    color *= 1.0 - minicol;
    minicol = paintminicol(mwidth, colb, colc, cola, rowd, rowf, rowe);         // BC DF
    color *= 1.0 - minicol;
    
    float mheight = 0.005; 
    float minirow = paintminirow(mheight, cola, colb, colc, rowe, rowf, rowd);     // AB EF
    color *= 1.0 - minirow;

    //glFragColor = vec4(color,1.0);

    // Output to screen
    glFragColor = vec4(color,1.0);
}
