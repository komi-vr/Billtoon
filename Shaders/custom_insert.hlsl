// --- Euler rotation helpers (XYZ order, degrees) ---

float3 RotateAroundX(float3 v, float angleRad)
{
    float s = sin(angleRad);
    float c = cos(angleRad);
    return float3(
        v.x,
        v.y * c - v.z * s,
        v.y * s + v.z * c
    );
}

float3 RotateAroundY(float3 v, float angleRad)
{
    float s = sin(angleRad);
    float c = cos(angleRad);
    return float3(
        v.x * c + v.z * s,
        v.y,
        -v.x * s + v.z * c
    );
}

float3 RotateAroundZ(float3 v, float angleRad)
{
    float s = sin(angleRad);
    float c = cos(angleRad);
    return float3(
        v.x * c - v.y * s,
        v.x * s + v.y * c,
        v.z
    );
}

// BillboardRotation.xyz (deg) を使って XYZ 順で回す
float3 ApplyBillboardEuler(float3 v, float3 eulerDeg)
{
    float3 r = radians(eulerDeg);
    v = RotateAroundX(v, r.x);
    v = RotateAroundY(v, r.y);
    v = RotateAroundZ(v, r.z);
    return v;
}


// localPosOS : メッシュのローカル頂点 (positionOS)
// posWS      : 既に計算済みのワールド座標（書き換える）
// normalWS   : 同上
// tangentWS, bitangentWS : 同上
void LilBillboardVertexWS(
    float3  localPosOS,
    inout float3 posWS,
    inout float3 normalWS,
    inout float3 tangentWS,
    inout float3 bitangentWS
){
    // 0: Off -> 何もしない
    if (_BillboardMode == BILLBOARD_MODE_OFF)
    {
        return;
    }

    // ビルボードの中心（オブジェクト原点のWS）
    float3 centerWS = mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).xyz;

    // オブジェクト→カメラ方向
    float3 toCamera = normalize(_WorldSpaceCameraPos - centerWS);

    float3 rightWS;
    float3 upWS;
    float3 forwardWS;

    if (_BillboardMode == BILLBOARD_MODE_YAXIS)
    {
        // --- Y軸固定ビルボード ---
        upWS = float3(0, 1, 0);

        float3 toCamXZ = float3(toCamera.x, 0.0, toCamera.z);
        if (all(abs(toCamXZ) < 1e-5))
        {
            toCamXZ = float3(0.0, 0.0, 1.0);
        }
        toCamXZ   = normalize(toCamXZ);
        forwardWS = toCamXZ;
        rightWS   = normalize(cross(upWS, forwardWS));
        forwardWS = normalize(cross(rightWS, upWS));
    }
    else // BILLBOARD_MODE_FULL
    {
        // --- 完全ビルボード ---
        forwardWS = normalize(toCamera);

        // カメラのロールは無視してワールドYを Up にする
        upWS = float3(0, 1, 0);
        if (abs(dot(forwardWS, upWS)) > 0.99)
        {
            upWS = float3(0, 0, 1);
        }

        rightWS = normalize(cross(upWS, forwardWS));
        upWS    = normalize(cross(forwardWS, rightWS));
    }

    // --- ここから「ローカル頂点に対して」スケール＆回転を掛ける ---

    // スケール
    float3 scale = _BillboardScale.xyz;
    float3 localOffset = localPosOS * scale;

    // 回転オフセット (Euler XYZ, deg)
    float3 euler = _BillboardRotation.xyz;
    if (any(euler != 0.0))
    {
        localOffset = ApplyBillboardEuler(localOffset, euler);
    }

    // ビルボード軸に乗せる
    posWS =
        centerWS
        + rightWS   * localOffset.x
        + upWS      * localOffset.y
        + forwardWS * localOffset.z;

    // 法線・接線：ビルボードの向きに合わせる
    normalWS    = forwardWS;
    tangentWS   = rightWS;
    bitangentWS = upWS;
}
