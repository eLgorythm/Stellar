async fn write_message<W: AsyncWriteExt + Unpin>(writer: &mut W, msg_type: u32, payload: &[u8]) -> anyhow::Result<()> {
    // Kirim 4 byte prefix (Type di byte pertama)
    let mut prefix = [0u8; 4];
    prefix[0] = msg_type as u8;
    writer.write_all(&prefix).await?;

    // Kirim 2 byte Length (Big Endian)
    writer.write_u16(payload.len() as u16).await?;

    // Kirim Payload
    writer.write_all(payload).await?;
    writer.flush().await?;
    
    debug!("Sent ADP Packet: Type={}, Len={}", msg_type, payload.len());
    Ok(())
}