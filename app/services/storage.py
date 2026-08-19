import io
from datetime import timedelta
from typing import BinaryIO, Optional, Union
from minio import Minio
from minio.error import S3Error

from app.core.config import settings

class MinIOStorage:
    def __init__(self):
        self.endpoint = settings.MINIO_ENDPOINT
        self.external_endpoint = settings.MINIO_EXTERNAL_ENDPOINT
        self.access_key = settings.MINIO_ACCESS_KEY
        self.secret_key = settings.MINIO_SECRET_KEY
        self.secure = settings.MINIO_SECURE
        self.region = settings.MINIO_REGION
        self.default_bucket = settings.MINIO_BUCKET_NAME

        # Client for internal container communication
        self.client = Minio(
            endpoint=self.endpoint,
            access_key=self.access_key,
            secret_key=self.secret_key,
            secure=self.secure,
            region=self.region
        )

        # Client for generating presigned URLs accessible from external network / client apps
        self.external_client = Minio(
            endpoint=self.external_endpoint,
            access_key=self.access_key,
            secret_key=self.secret_key,
            secure=self.secure,
            region=self.region
        )

    def ensure_bucket_exists(self, bucket_name: Optional[str] = None) -> str:
        """
        Check if the specified bucket exists, creating it if it does not.
        """
        target_bucket = bucket_name or self.default_bucket
        try:
            if not self.client.bucket_exists(target_bucket):
                self.client.make_bucket(target_bucket, location=self.region)
        except S3Error as err:
            raise RuntimeError(f"Error ensuring MinIO bucket exists: {err}")
        return target_bucket

    def upload_file(
        self,
        file_data: Union[bytes, BinaryIO],
        object_name: str,
        length: int = -1,
        content_type: str = "application/octet-stream",
        bucket_name: Optional[str] = None
    ) -> str:
        """
        Upload binary data or a file stream to MinIO storage.
        Returns the stored object name.
        """
        target_bucket = self.ensure_bucket_exists(bucket_name)

        if isinstance(file_data, bytes):
            stream = io.BytesIO(file_data)
            data_length = len(file_data)
            part_size = 0
        else:
            stream = file_data
            data_length = length
            part_size = 10 * 1024 * 1024 if length == -1 else 0

        try:
            self.client.put_object(
                bucket_name=target_bucket,
                object_name=object_name,
                data=stream,
                length=data_length,
                part_size=part_size,
                content_type=content_type
            )
        except S3Error as err:
            raise RuntimeError(f"Failed to upload file to MinIO: {err}")

        return object_name

    def download_file(
        self,
        object_name: str,
        bucket_name: Optional[str] = None
    ) -> bytes:
        """
        Download raw file bytes from MinIO storage bucket.
        """
        target_bucket = bucket_name or self.default_bucket
        try:
            response = self.client.get_object(target_bucket, object_name)
            data = response.read()
            response.close()
            response.release_conn()
            return data
        except S3Error as err:
            raise RuntimeError(f"Failed to download file from MinIO: {err}")

    def get_presigned_url(
        self,
        object_name: str,
        expires_seconds: int = 3600,
        bucket_name: Optional[str] = None
    ) -> str:
        """
        Generate a secure presigned URL for GET access to an object.
        Uses external_client so HMAC signatures match external requests.
        """
        target_bucket = bucket_name or self.default_bucket
        try:
            url = self.external_client.presigned_get_object(
                bucket_name=target_bucket,
                object_name=object_name,
                expires=timedelta(seconds=expires_seconds)
            )
            return url
        except S3Error as err:
            raise RuntimeError(f"Failed to generate presigned URL: {err}")

    def delete_file(
        self,
        object_name: str,
        bucket_name: Optional[str] = None
    ) -> bool:
        """
        Delete an object from the MinIO storage bucket.
        """
        target_bucket = bucket_name or self.default_bucket
        try:
            self.client.remove_object(
                bucket_name=target_bucket,
                object_name=object_name
            )
            return True
        except S3Error as err:
            raise RuntimeError(f"Failed to delete file from MinIO: {err}")

storage_service = MinIOStorage()
